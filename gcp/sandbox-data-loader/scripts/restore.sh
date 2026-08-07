#!/usr/bin/env bash
# =============================================================================
# scripts/restore.sh — Restore dump into sandbox Cloud SQL database
# =============================================================================
#
# Reads from:
#   TARGET_PROJECT, TARGET_REGION, TARGET_INSTANCE (proxy already running on 5433)
#   TARGET_DB, TARGET_DB_USER
#   SOURCE_DB, SOURCE_DB_USER (for extension extraction)
#   DUMP_GCS_PATH  : set by dump.sh (or set manually for standalone use)
#   DUMP_TIMESTAMP : set by dump.sh (or set manually)
#   GCS_BUCKET     : used to derive DUMP_GCS_PATH if not set
#
# This script can be run independently (e.g., to re-apply a specific dump):
#   export DUMP_GCS_PATH=gs://my-bucket/dumps/dump_20260618_102345.sql
#   set -a; source .env; set +a; ./scripts/restore.sh
#
# Key steps:
#   1. Download dump from GCS
#   2. Drop + recreate target database (via Cloud SQL Admin API) and grant
#      ALL ON DATABASE to DB_OWNER_ROLE (so pipeline user inherits CREATE)
#   3. Extract + recreate PostgreSQL extensions in target DB
#   4. Restore the dump with psql (ON_ERROR_STOP=1)
#   5. Verify row counts
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/log.sh"

# =============================================================================
# Configuration & defaults
# =============================================================================
TARGET_SCHEMA="${TARGET_SCHEMA:-public}"
SOURCE_SCHEMA="${SOURCE_SCHEMA:-public}"
TARGET_PGHOST="${TARGET_PGHOST:-127.0.0.1}"
TARGET_PGPORT="${TARGET_PGPORT:-5434}"
SOURCE_PGHOST="${SOURCE_PGHOST:-127.0.0.1}"
SOURCE_PGPORT="${SOURCE_PGPORT:-5432}"
DUMP_FILE="/tmp/loader/restore_dump.sql"

# Shared table list written by dump.sh (tables_only mode): TABLE_LIST + FK-referenced tables
# FK_DEPTH=-1: used to TRUNCATE the tables before data-only restore (no CASCADE damage).
# FK_DEPTH=0:  used to DROP CASCADE before full DDL restore (FKs stripped in dump).
SHARED_TABLES_FILE="/tmp/loader/all_restore_tables_${DUMP_TIMESTAMP:-}.txt"

# Derive DUMP_GCS_PATH — priority: explicit path > local dump > reload latest > DUMP_TIMESTAMP
if [[ -z "${DUMP_GCS_PATH:-}" ]]; then
  if [[ "${MODE:-full_refresh}" == "reload" ]]; then
    if [[ -z "${GCS_BUCKET:-}" ]]; then
      die "MODE=reload requires GCS_BUCKET to locate the dump."
    fi
    latest=$(gcloud storage ls "gs://${GCS_BUCKET}/dumps/dump_*.sql" 2>/dev/null | sort | tail -1)
    if [[ -z "${latest}" ]]; then
      die "No dumps found in gs://${GCS_BUCKET}/dumps/ — cannot reload."
    fi
    DUMP_GCS_PATH="${latest}"
    log_info "Reload: using latest dump ${DUMP_GCS_PATH}"
  elif [[ -n "${DUMP_TIMESTAMP:-}" ]]; then
    if [[ -z "${GCS_BUCKET:-}" ]]; then
      DUMP_GCS_PATH="/tmp/loader/dump_${DUMP_TIMESTAMP}.sql"
      log_info "GCS_BUCKET not set — using local dump: ${DUMP_GCS_PATH}"
    else
      DUMP_GCS_PATH="gs://${GCS_BUCKET}/dumps/dump_${DUMP_TIMESTAMP}.sql"
    fi
  else
    die "Neither DUMP_GCS_PATH nor DUMP_TIMESTAMP is set. Cannot locate dump file."
  fi
fi

mkdir -p /tmp/loader

# =============================================================================
# Helper: run psql against the TARGET database
# =============================================================================
target_psql() {
  psql -h "${TARGET_PGHOST}" -p "${TARGET_PGPORT}" -U "${TARGET_DB_USER}" -d "${TARGET_DB}" "$@"
}

# Helper: run psql against the SOURCE database
source_psql() {
  psql -h "${SOURCE_PGHOST}" -p "${SOURCE_PGPORT}" -U "${SOURCE_DB_USER}" -d "${SOURCE_DB}" "$@"
}

# =============================================================================
# Step 1: Download dump from GCS
# =============================================================================
download_dump() {
  if [[ "${DUMP_GCS_PATH}" == *.gz ]]; then
    log_info "Gzipped dump — will stream directly from GCS during restore."
    return 0
  fi

  # Local dump path — already at DUMP_FILE, skip download
  if [[ "${DUMP_GCS_PATH}" == /* ]]; then
    if [[ "${DUMP_GCS_PATH}" != "${DUMP_FILE}" ]]; then
      cp "${DUMP_GCS_PATH}" "${DUMP_FILE}"
    fi
    log_info "Using local dump: ${DUMP_GCS_PATH}"
    return 0
  fi

  log_info "Downloading dump from ${DUMP_GCS_PATH}..."
  gcloud storage cp "${DUMP_GCS_PATH}" "${DUMP_FILE}"
  local size
  size=$(du -sh "${DUMP_FILE}" | cut -f1)
  log_info "Downloaded dump (${size}): ${DUMP_FILE}"
}

# =============================================================================
# Step 2: Extract extensions from source and recreate in target
# =============================================================================
# Extensions must be created BEFORE restoring the dump because the dump SQL
# may reference extension-provided types or functions.
setup_extensions() {
  log_info "Extracting extensions from source database..."

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${SOURCE_DB_USER}"

  local extensions_sql="/tmp/loader/extensions.sql"

  source_psql \
    --tuples-only \
    --no-align \
    -c "
      SELECT 'CREATE EXTENSION IF NOT EXISTS \"' || e.extname || '\" WITH SCHEMA ' || n.nspname || ';'
      FROM pg_extension e
      JOIN pg_namespace n ON e.extnamespace = n.oid
      WHERE n.nspname = '${SOURCE_SCHEMA}'
        AND e.extname NOT IN ('plpgsql')  -- plpgsql is always present
      ORDER BY e.extname;
    " > "${extensions_sql}"

  unset PGPASSWORD PGUSER

  if [[ ! -s "${extensions_sql}" ]]; then
    log_info "No additional extensions found in source (besides plpgsql)."
    return 0
  fi

  log_info "Generated $(wc -l < "${extensions_sql}") extension(s)"

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  log_info "Creating extensions in target database..."
  target_psql -f "${extensions_sql}"

  unset PGPASSWORD PGUSER

  log_info "Extensions created successfully."
}

# =============================================================================
# Step 3: Create DB_OWNER_ROLE in target (before restore)
# =============================================================================
# Even though pg_dump uses --no-owner (no ownership statements in the dump),
# the non-login owner role must exist before restore because:
#   - grant.sh will REASSIGN OWNED from TARGET_DB_USER to DB_OWNER_ROLE
#   - Any stored procedures/views that reference the role by name need it present
#   - Avoids role-does-not-exist errors if the dump contains any role references
setup_owner_role() {
  local owner_role="${DB_OWNER_ROLE:-}"
  if [[ -z "$owner_role" ]]; then
    log_warn "DB_OWNER_ROLE is not set — skipping non-login owner role setup."
    return 0
  fi

  log_info "Creating non-login owner role '${owner_role}' in ${TARGET_DB} (if not exists)..."

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  target_psql <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${owner_role}') THEN
    EXECUTE format('CREATE ROLE %I NOLOGIN', '${owner_role}');
    RAISE NOTICE 'Created non-login owner role: ${owner_role}';
  ELSE
    RAISE NOTICE 'Non-login owner role already exists: ${owner_role}';
  END IF;
END
\$\$;
SQL

  # Note: recreate_database() already runs 'GRANT ALL ON DATABASE ... TO
  # DB_OWNER_ROLE' via SET ROLE cloudsqlsuperuser. This GRANT is redundant
  # for full_refresh / wipe paths, but kept because setup_owner_role() is
  # also called from tables_only / drop_tables / truncate_tables modes (which
  # do NOT recreate the DB) — those paths still need to ensure the owner
  # role holds DB privileges. Do NOT swallow stderr — silencing it hid a
  # real failure previously.
  log_info "Granting ALL PRIVILEGES ON DATABASE ${TARGET_DB} to ${owner_role}..."
  target_psql \
    --set ON_ERROR_STOP=1 \
    -c "GRANT ALL PRIVILEGES ON DATABASE \"${TARGET_DB}\" TO \"${owner_role}\";" \
    || log_warn "Could not grant ALL on database ${TARGET_DB} to ${owner_role}"

  unset PGPASSWORD PGUSER
  log_info "Owner role '${owner_role}' is ready."
}



# =============================================================================
# Step 3b: Create custom types used by target tables (tables_only mode)
# =============================================================================
# pg_dump -t does NOT include dependent types (enums, domains, composites).
# Extract them from the source and create them in the target before restore.
# Uses recursive CTE to handle transitive deps (e.g. domain wrapping an enum).
setup_types() {
  local tables="${1:-${TABLE_LIST:-}}"
  if [[ -z "$tables" ]]; then
    log_warn "No tables specified — skipping custom type extraction."
    return 0
  fi

  log_info "Extracting custom types used by: ${tables}"

  # Ensure schema exists in target
  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"
  target_psql \
    --set ON_ERROR_STOP=1 \
    -c "CREATE SCHEMA IF NOT EXISTS ${SOURCE_SCHEMA};" 2>/dev/null || true
  unset PGPASSWORD PGUSER

  # Extract types from source using recursive CTE to walk dependency chain
  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${SOURCE_DB_USER}"

  local types_sql="/tmp/loader/types.sql"

  source_psql --tuples-only --no-align > "${types_sql}" <<SQL
    WITH RECURSIVE
      table_list AS (
        SELECT regexp_split_to_table('${tables}', ',') AS relname
      ),
      table_oids AS (
        SELECT c.oid
        FROM pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN table_list tn ON trim(tn.relname) = c.relname
        WHERE n.nspname = '${SOURCE_SCHEMA}'
      ),
      direct_types AS (
        SELECT DISTINCT a.atttypid AS oid
        FROM pg_attribute a
        WHERE a.attrelid IN (SELECT oid FROM table_oids)
          AND a.attnum > 0 AND NOT a.attisdropped
      ),
      all_deps AS (
        SELECT oid FROM direct_types
        UNION
        SELECT CASE t.typtype
          WHEN 'd' THEN t.typbasetype
          WHEN 'c' THEN a.atttypid
        END
        FROM pg_type t
        JOIN all_deps d ON t.oid = d.oid
        LEFT JOIN pg_attribute a ON a.attrelid = t.typrelid
          AND a.attnum > 0 AND NOT a.attisdropped
        WHERE ((t.typtype = 'd' AND t.typbasetype != 0)
            OR (t.typtype = 'c' AND t.typrelid != 0 AND a.atttypid IS NOT NULL))
      ),
      dep_types AS (
        SELECT DISTINCT oid FROM all_deps
        WHERE oid NOT IN (
          SELECT t.oid FROM pg_type t
          WHERE t.typnamespace = 'pg_catalog'::regnamespace
        )
      )

    -- Enums, domains, and composites combined into one query (CTE only scoped to one SELECT)
    SELECT 'CREATE TYPE ' || quote_ident(n.nspname) || '.' || quote_ident(t.typname) || ' AS ENUM (' ||
           string_agg(quote_literal(e.enumlabel), ', ' ORDER BY e.enumsortorder) || ');'
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    JOIN pg_enum e ON e.enumtypid = t.oid
    WHERE t.oid IN (SELECT oid FROM dep_types)
      AND t.typtype = 'e'
    GROUP BY n.nspname, t.typname
    UNION ALL
    SELECT 'CREATE DOMAIN ' || quote_ident(n.nspname) || '.' || quote_ident(t.typname) || ' AS ' ||
           pg_catalog.format_type(t.typbasetype, t.typtypmod) ||
           CASE WHEN t.typnotnull THEN ' NOT NULL' ELSE '' END || ';'
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.oid IN (SELECT oid FROM dep_types)
      AND t.typtype = 'd'
    UNION ALL
    SELECT 'CREATE TYPE ' || quote_ident(n.nspname) || '.' || quote_ident(t.typname) || ' AS (' ||
           string_agg(quote_ident(a.attname) || ' ' || pg_catalog.format_type(a.atttypid, a.atttypmod),
             ', ' ORDER BY a.attnum) || ');'
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    JOIN pg_attribute a ON a.attrelid = t.typrelid
    WHERE t.oid IN (SELECT oid FROM dep_types)
      AND t.typtype = 'c'
      AND a.attnum > 0 AND NOT a.attisdropped
    GROUP BY n.nspname, t.typname;
SQL

  unset PGPASSWORD PGUSER

  if [[ ! -s "${types_sql}" ]]; then
    log_info "No custom types found in source."
    return 0
  fi

  log_info "Generated $(wc -l < "${types_sql}") type definition(s)"

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  # Filter out types that already exist in target
  local exclude_file="/tmp/loader/exclude_types.txt"
  target_psql --tuples-only --no-align -c "
    SELECT '^CREATE TYPE ' || quote_ident(n.nspname) || '.' || quote_ident(t.typname) || ' '
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE n.nspname = '${TARGET_SCHEMA}'
      AND t.typtype IN ('e', 'd', 'c')
  " > "${exclude_file}" 2>/dev/null || true
  if [[ -s "${exclude_file}" ]]; then
    local before after
    before=$(wc -l < "${types_sql}")
    grep -v -f "${exclude_file}" "${types_sql}" > "${types_sql}.filtered" || true
    mv "${types_sql}.filtered" "${types_sql}"
    after=$(wc -l < "${types_sql}")
    log_info "Filtered out $(( before - after )) type(s) that already exist in target"
  fi
  rm -f "${exclude_file}"

  if [[ ! -s "${types_sql}" ]]; then
    unset PGPASSWORD PGUSER
    log_info "All custom types already exist in target — nothing to create."
    rm -f "${types_sql}"
    return 0
  fi

  psql \
    -h "${TARGET_PGHOST}" \
    -p "${TARGET_PGPORT}" \
    -U "${TARGET_DB_USER}" \
    -d "${TARGET_DB}" \
    --set ON_ERROR_STOP=0 \
    -f "${types_sql}"

  unset PGPASSWORD PGUSER
  rm -f "${types_sql}"

  log_info "Custom types created successfully."
}

# =============================================================================
# Step 3d: Sync all functions from source to target (sync_only mode)
# =============================================================================
sync_functions() {
  log_info "Extracting functions from source database..."

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${SOURCE_DB_USER}"

  local func_sql="/tmp/loader/functions.sql"

  source_psql --tuples-only --no-align > "${func_sql}" <<SQL
    SELECT regexp_replace(pg_get_functiondef(p.oid), '^CREATE FUNCTION', 'CREATE OR REPLACE FUNCTION') || ';'
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    JOIN pg_language l ON p.prolang = l.oid
    WHERE n.nspname = '${SOURCE_SCHEMA}'
      AND p.prokind = 'f'
      AND l.lanname != 'c'
    ORDER BY p.proname;
SQL

  unset PGPASSWORD PGUSER

  if [[ ! -s "${func_sql}" ]]; then
    log_info "No functions found in source."
    return 0
  fi

  log_info "Generated $(wc -l < "${func_sql}") function definition(s)"

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  psql \
    -h "${TARGET_PGHOST}" \
    -p "${TARGET_PGPORT}" \
    -U "${TARGET_DB_USER}" \
    -d "${TARGET_DB}" \
    --set ON_ERROR_STOP=0 \
    -f "${func_sql}"

  unset PGPASSWORD PGUSER
  rm -f "${func_sql}"

  log_info "Functions created successfully."
}

# =============================================================================
# Step 3c: Sync all sequences from source to target (sync_only mode)
# =============================================================================
sync_sequences() {
  log_info "Extracting sequences from source database..."

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${SOURCE_DB_USER}"

  local seq_sql="/tmp/loader/sequences.sql"

  source_psql --tuples-only --no-align > "${seq_sql}" <<SQL
    SELECT 'CREATE SEQUENCE IF NOT EXISTS ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) ||
           ' START WITH ' || coalesce(s.seqstart, 1) ||
           ' INCREMENT BY ' || s.seqincrement ||
           ' MINVALUE ' || s.seqmin ||
           ' MAXVALUE ' || s.seqmax ||
           ' CACHE ' || s.seqcache ||
           CASE WHEN s.seqcycle THEN ' CYCLE' ELSE ' NO CYCLE' END || ';'
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_sequence s ON c.oid = s.seqrelid
    WHERE n.nspname = '${SOURCE_SCHEMA}'
      AND c.relkind = 'S'
    ORDER BY c.relname;
SQL

  unset PGPASSWORD PGUSER

  if [[ ! -s "${seq_sql}" ]]; then
    log_info "No sequences found in source."
    return 0
  fi

  log_info "Generated $(wc -l < "${seq_sql}") sequence definition(s)"

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  psql \
    -h "${TARGET_PGHOST}" \
    -p "${TARGET_PGPORT}" \
    -U "${TARGET_DB_USER}" \
    -d "${TARGET_DB}" \
    --set ON_ERROR_STOP=0 \
    -f "${seq_sql}"

  unset PGPASSWORD PGUSER
  rm -f "${seq_sql}"

  log_info "Sequences created successfully."
}

# =============================================================================
# Step 3d: Sync ALL custom types from source to target (sync_only mode)
# =============================================================================
sync_all_types() {
  log_info "Extracting all custom types from source database..."

  # Ensure schema exists in target
  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"
  target_psql \
    --set ON_ERROR_STOP=1 \
    -c "CREATE SCHEMA IF NOT EXISTS ${SOURCE_SCHEMA};" 2>/dev/null || true
  unset PGPASSWORD PGUSER

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${SOURCE_DB_USER}"

  local types_sql="/tmp/loader/types.sql"

  source_psql --tuples-only --no-align > "${types_sql}" <<SQL
    WITH RECURSIVE
      direct_types AS (
        SELECT t.oid
        FROM pg_type t
        JOIN pg_namespace n ON t.typnamespace = n.oid
        LEFT JOIN pg_class c ON t.typrelid = c.oid
        WHERE n.nspname = '${SOURCE_SCHEMA}'
          AND t.typtype IN ('e', 'd', 'c')
          AND (t.typtype != 'c' OR c.relkind = 'c')
      ),
      domain_deps AS (
        SELECT oid FROM direct_types
        UNION
        SELECT t.typbasetype
        FROM pg_type t, domain_deps d
        WHERE t.oid = d.oid AND t.typtype = 'd' AND t.typbasetype != 0
      ),
      composite_deps AS (
        SELECT oid FROM direct_types
        UNION
        SELECT a.atttypid
        FROM pg_type t, composite_deps d, pg_attribute a
        WHERE t.oid = d.oid AND t.typtype = 'c' AND t.typrelid != 0
          AND a.attrelid = t.typrelid AND a.attnum > 0
          AND NOT a.attisdropped
      ),
      dep_types AS (
        SELECT oid FROM direct_types
        UNION
        SELECT oid FROM domain_deps
        UNION
        SELECT oid FROM composite_deps
        EXCEPT
        SELECT t.oid FROM pg_type t
        WHERE t.typnamespace = 'pg_catalog'::regnamespace
      )

    SELECT 'CREATE TYPE ' || quote_ident(n.nspname) || '.' || quote_ident(t.typname) || ' AS ENUM (' ||
           string_agg(quote_literal(e.enumlabel), ', ' ORDER BY e.enumsortorder) || ');'
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    JOIN pg_enum e ON e.enumtypid = t.oid
    WHERE t.oid IN (SELECT oid FROM dep_types)
      AND t.typtype = 'e'
    GROUP BY n.nspname, t.typname
    UNION ALL
    SELECT 'CREATE DOMAIN ' || quote_ident(n.nspname) || '.' || quote_ident(t.typname) || ' AS ' ||
           pg_catalog.format_type(t.typbasetype, t.typtypmod) ||
           CASE WHEN t.typnotnull THEN ' NOT NULL' ELSE '' END || ';'
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.oid IN (SELECT oid FROM dep_types)
      AND t.typtype = 'd'
    UNION ALL
    SELECT 'CREATE TYPE ' || quote_ident(n.nspname) || '.' || quote_ident(t.typname) || ' AS (' ||
           string_agg(quote_ident(a.attname) || ' ' || pg_catalog.format_type(a.atttypid, a.atttypmod),
             ', ' ORDER BY a.attnum) || ');'
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    JOIN pg_attribute a ON a.attrelid = t.typrelid
    WHERE t.oid IN (SELECT oid FROM dep_types)
      AND t.typtype = 'c'
      AND a.attnum > 0 AND NOT a.attisdropped
    GROUP BY n.nspname, t.typname;
SQL

  unset PGPASSWORD PGUSER

  if [[ ! -s "${types_sql}" ]]; then
    log_info "No custom types found in source."
    return 0
  fi

  log_info "Generated $(wc -l < "${types_sql}") type definition(s)"

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  # Filter out types that already exist in target
  local exclude_file="/tmp/loader/exclude_types.txt"
  target_psql --tuples-only --no-align -c "
    SELECT '^CREATE TYPE ' || quote_ident(n.nspname) || '.' || quote_ident(t.typname) || ' '
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE n.nspname = '${TARGET_SCHEMA}'
      AND t.typtype IN ('e', 'd', 'c')
  " > "${exclude_file}" 2>/dev/null || true
  if [[ -s "${exclude_file}" ]]; then
    local before after
    before=$(wc -l < "${types_sql}")
    grep -v -f "${exclude_file}" "${types_sql}" > "${types_sql}.filtered" || true
    mv "${types_sql}.filtered" "${types_sql}"
    after=$(wc -l < "${types_sql}")
    log_info "Filtered out $(( before - after )) type(s) that already exist in target"
  fi
  rm -f "${exclude_file}"

  if [[ ! -s "${types_sql}" ]]; then
    unset PGPASSWORD PGUSER
    log_info "All custom types already exist in target — nothing to create."
    rm -f "${types_sql}"
    return 0
  fi

  psql \
    -h "${TARGET_PGHOST}" \
    -p "${TARGET_PGPORT}" \
    -U "${TARGET_DB_USER}" \
    -d "${TARGET_DB}" \
    --set ON_ERROR_STOP=0 \
    -f "${types_sql}"

  unset PGPASSWORD PGUSER
  rm -f "${types_sql}"

  log_info "Custom types created successfully."
}


# =============================================================================
# Step 4: Drop and recreate target database
# =============================================================================
recreate_database() {
  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  if [[ "${USE_PROXY:-false}" == "true" ]] && command -v gcloud &>/dev/null && [[ -n "${TARGET_INSTANCE:-}" ]]; then
    # Cloud SQL path: use GCP API to drop/create database
    log_info "Dropping and recreating database: ${TARGET_DB} via GCP API..."

    gcloud sql databases delete "${TARGET_DB}" \
      --instance="${TARGET_INSTANCE}" \
      --project="${TARGET_PROJECT}" \
      --quiet || log_warn "Database ${TARGET_DB} may not exist yet."

    gcloud sql databases create "${TARGET_DB}" \
      --instance="${TARGET_INSTANCE}" \
      --project="${TARGET_PROJECT}" \
      --quiet || die "Failed to create database ${TARGET_DB}."

    # Cloud SQL creates the DB owned by 'cloudsqlsuperuser'. The pipeline user
    # (TARGET_DB_USER) is typically NOT a direct member of that role, so it has
    # no CREATE on the DB and any 'GRANT ... ON DATABASE' it issues is a silent
    # no-op. For non-'public' schemas the dump contains 'CREATE SCHEMA <name>',
    # which then fails with 'permission denied for database'.
    #
    # Strategy: keep 'cloudsqlsuperuser' as the DB owner (transferring ownership
    # requires the executor to be a member of BOTH old and new owner — a chain
    # that doesn't naturally exist and isn't worth engineering). Instead, GRANT
    # ALL ON DATABASE to DB_OWNER_ROLE from a session that's acting as the DB
    # owner. Role *privileges* (unlike role *attributes*) DO inherit via role
    # membership in PG 15, so any user that's a member of DB_OWNER_ROLE — such
    # as the pipeline TARGET_DB_USER via its chain to DB_OWNER_ROLE — will
    # automatically pick up CREATE on the DB and can run 'CREATE SCHEMA'.
    #
    # Why SET ROLE 'cloudsqlsuperuser' here: to GRANT on a database you must
    # currently be its owner (or a superuser). TARGET_DB_USER is neither, but
    # it IS a member of 'cloudsqlsuperuser' (see one-time DBA bootstrap below)
    # and SET ROLE lets it act as the owner for this statement only.
    #
    # One-time bootstrap required (run once by a DBA / cloudsqlsuperuser):
    #   GRANT cloudsqlsuperuser TO <TARGET_DB_USER-or-parent-admin-role>;
    # Without that, SET ROLE fails with 'permission denied to set role
    # "cloudsqlsuperuser"' — fix is the grant, not more script workarounds.
    #
    # After restore, grant.sh runs REASSIGN OWNED BY TARGET_DB_USER TO
    # DB_OWNER_ROLE to transfer ownership of created objects (schema, tables,
    # sequences) to DB_OWNER_ROLE. The database object itself remains owned by
    # cloudsqlsuperuser — harmless because DB_OWNER_ROLE has ALL on it.
    if [[ -n "${DB_OWNER_ROLE:-}" ]]; then
      log_info "Granting ALL ON DATABASE ${TARGET_DB} to '${DB_OWNER_ROLE}' (via SET ROLE cloudsqlsuperuser)..."
      target_psql -d postgres \
        --set ON_ERROR_STOP=1 \
        -c "SET ROLE \"cloudsqlsuperuser\"; GRANT ALL ON DATABASE \"${TARGET_DB}\" TO \"${DB_OWNER_ROLE}\"; RESET ROLE;" \
        || die "Failed to grant ALL ON DATABASE ${TARGET_DB} to ${DB_OWNER_ROLE}. Ensure '${TARGET_DB_USER}' (or a parent role) has membership in 'cloudsqlsuperuser' via a DBA."
    else
      log_warn "DB_OWNER_ROLE not set — pipeline user will have no CREATE on ${TARGET_DB} (CREATE SCHEMA on non-public schemas will fail)."
    fi
  else
    # Local PostgreSQL path: use SQL to drop/create database
    log_info "Dropping and recreating database: ${TARGET_DB} via SQL..."

    psql -h "${TARGET_PGHOST}" -p "${TARGET_PGPORT}" -U "${TARGET_DB_USER}" -d postgres \
      --set ON_ERROR_STOP=1 \
      -c "DROP DATABASE IF EXISTS \"${TARGET_DB}\" WITH (FORCE);" \
      || log_warn "Database ${TARGET_DB} may not exist yet."

    psql -h "${TARGET_PGHOST}" -p "${TARGET_PGPORT}" -U "${TARGET_DB_USER}" -d postgres \
      --set ON_ERROR_STOP=1 \
      -c "CREATE DATABASE \"${TARGET_DB}\";" \
      || die "Failed to create database ${TARGET_DB}."

    if [[ -n "${DB_OWNER_ROLE:-}" ]]; then
      log_info "Granting ALL ON DATABASE ${TARGET_DB} to '${DB_OWNER_ROLE}'..."
      psql -h "${TARGET_PGHOST}" -p "${TARGET_PGPORT}" -U "${TARGET_DB_USER}" -d postgres \
        --set ON_ERROR_STOP=1 \
        -c "GRANT ALL ON DATABASE \"${TARGET_DB}\" TO \"${DB_OWNER_ROLE}\";" \
        || log_warn "Could not grant ALL on database ${TARGET_DB} to ${DB_OWNER_ROLE}"
    fi
  fi

  unset PGPASSWORD PGUSER
  log_info "Database ${TARGET_DB} recreated."
}

# =============================================================================
# Step 5: Restore the dump
# =============================================================================
restore_dump() {
  log_info "Restoring dump into ${TARGET_DB}..."

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  # Common base filter for all restore paths (strips PG17+ GUCs)
  local base_filter=(grep -v -E '^SET transaction_timeout')

  # Make CREATE SEQUENCE idempotent — PG15 supports IF NOT EXISTS (since 9.5).
  # When tables_only runs on a target with orphaned sequences from a prior run,
  # bare CREATE SEQUENCE would fail; this lets it pass harmlessly.
  local seq_iif_filter=(sed 's/^CREATE SEQUENCE /CREATE SEQUENCE IF NOT EXISTS /')

  # Make CREATE SCHEMA idempotent — schema may or may not exist in target.
  local schema_iif_filter=(sed 's/^CREATE SCHEMA /CREATE SCHEMA IF NOT EXISTS /')

  # FK_DEPTH=0: strip ALTER TABLE ... FOREIGN KEY ... ; statements (multi-line safe)
  local fk_filter=()
  if [[ "${FK_DEPTH:--1}" == "0" ]]; then
    log_info "FK_DEPTH=0 — stripping FOREIGN KEY constraint statements"
    fk_filter=(awk '
/^ALTER TABLE( ONLY)? /{
  if ($0 ~ /;/) {
    if ($0 !~ /FOREIGN KEY/) print
    next
  }
  block = $0; in_block = 1; next
}
in_block { block = block "\n" $0 }
in_block && /;/ {
  if (block !~ /FOREIGN KEY/) print block
  in_block = 0; next
}
!in_block { print }
')
  fi

  if [[ "${DUMP_GCS_PATH}" == *.gz ]]; then
    log_info "Streaming gzipped dump from ${DUMP_GCS_PATH}..."
    if [[ ${#fk_filter[@]} -gt 0 ]]; then
      gcloud storage cp "${DUMP_GCS_PATH}" - \
        | gunzip \
        | "${base_filter[@]}" \
        | "${schema_iif_filter[@]}" \
        | "${seq_iif_filter[@]}" \
        | "${fk_filter[@]}" \
        | target_psql --set ON_ERROR_STOP=1
    else
      gcloud storage cp "${DUMP_GCS_PATH}" - \
        | gunzip \
        | "${base_filter[@]}" \
        | "${schema_iif_filter[@]}" \
        | "${seq_iif_filter[@]}" \
        | target_psql --set ON_ERROR_STOP=1
    fi
  else
    if [[ ${#fk_filter[@]} -gt 0 ]]; then
      < "${DUMP_FILE}" "${base_filter[@]}" \
        | "${schema_iif_filter[@]}" \
        | "${seq_iif_filter[@]}" \
        | "${fk_filter[@]}" \
        | target_psql --set ON_ERROR_STOP=1
    else
      < "${DUMP_FILE}" "${base_filter[@]}" \
        | "${schema_iif_filter[@]}" \
        | "${seq_iif_filter[@]}" \
        | target_psql --set ON_ERROR_STOP=1
    fi

    rm -f "${DUMP_FILE}"
  fi

  unset PGPASSWORD PGUSER

  log_info "Restore complete."
}

# =============================================================================
# Step 6: Verify restore (row counts per table)
# =============================================================================
verify_restore() {
  log_info "Verifying restore — row counts per table:"

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  target_psql --tuples-only -c "
    SELECT schemaname || '.' || tablename AS table,
           pg_total_relation_size(schemaname || '.' || tablename) AS size_bytes,
           (SELECT reltuples::bigint FROM pg_class c
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = schemaname AND c.relname = tablename) AS approx_rows
    FROM pg_tables
    WHERE schemaname = '${TARGET_SCHEMA}'
    ORDER BY schemaname, tablename;
  " || log_warn "Could not retrieve row counts (non-fatal)."

  unset PGPASSWORD PGUSER
}

# =============================================================================
# FK handling (tables_only FK_DEPTH=-1)
# =============================================================================
# When tables_only restores a subset of tables into existing schema, FK
# constraints can cause two problems:
#
#   1. CASCADE damage: TRUNCATE restored-table CASCADE would also truncate
#      non-restored tables that have FKs referencing restored tables.
#   2. COPY violations: circular FKs between restored tables (e.g. businesses
#      and filings) cause constraint violations during data COPY.
#
# Solution: save ALL FK definitions involving restored tables (as either
# referencing or referenced side), drop them before TRUNCATE+COPY, and
# recreate with NOT VALID after restore — no recheck of existing data.
handle_fks() {
  local table_list_csv="$1"

  if [[ -z "$table_list_csv" ]]; then
    return 0
  fi

  local in_list=""
  IFS=',' read -ra tables <<< "$table_list_csv"
  for t in "${tables[@]}"; do
    t="$(echo "$t" | xargs)"
    in_list="${in_list:+${in_list},}'${t}'"
  done

  local fk_drop_sql="/tmp/loader/fk_drop.sql"
  local fk_add_sql="/tmp/loader/fk_add.sql"

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  target_psql --tuples-only --no-align -c "
    SELECT 'ALTER TABLE ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) ||
           ' DROP CONSTRAINT ' || quote_ident(con.conname) || ';'
    FROM pg_constraint con
    JOIN pg_class c ON con.conrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_class ref_c ON con.confrelid = ref_c.oid
    JOIN pg_namespace ref_n ON ref_c.relnamespace = ref_n.oid
    WHERE con.contype = 'f'
      AND n.nspname = '${TARGET_SCHEMA}'
      AND ((c.relname IN (${in_list}) OR ref_c.relname IN (${in_list})))
    ORDER BY con.conname;
  " > "$fk_drop_sql" 2>/dev/null || true

  target_psql --tuples-only --no-align -c "
    SELECT 'ALTER TABLE ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) ||
           ' ADD CONSTRAINT ' || quote_ident(con.conname) || ' ' ||
           pg_get_constraintdef(con.oid) || ' NOT VALID;'
    FROM pg_constraint con
    JOIN pg_class c ON con.conrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_class ref_c ON con.confrelid = ref_c.oid
    JOIN pg_namespace ref_n ON ref_c.relnamespace = ref_n.oid
    WHERE con.contype = 'f'
      AND n.nspname = '${TARGET_SCHEMA}'
      AND ((c.relname IN (${in_list}) OR ref_c.relname IN (${in_list})))
    ORDER BY con.conname;
  " > "$fk_add_sql" 2>/dev/null || true

  unset PGPASSWORD PGUSER

  if [[ ! -s "$fk_drop_sql" ]]; then
    log_info "No FK constraints to save on restored tables."
    rm -f "$fk_drop_sql" "$fk_add_sql"
    return 0
  fi

  local count
  count=$(wc -l < "$fk_drop_sql")
  log_info "Saving and dropping ${count} FK constraint(s) involving restored tables..."

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"
  target_psql \
    --set ON_ERROR_STOP=1 \
    -c "CREATE SCHEMA IF NOT EXISTS ${SOURCE_SCHEMA};" 2>/dev/null || true

  target_psql \
    --set ON_ERROR_STOP=1 \
    -f "$fk_drop_sql" || true
  unset PGPASSWORD PGUSER

  rm -f "$fk_drop_sql"
  log_info "FK constraints dropped."
}

restore_saved_fks() {
  local fk_add_file="/tmp/loader/fk_add.sql"
  if [[ ! -s "$fk_add_file" ]]; then
    rm -f "$fk_add_file" 2>/dev/null || true
    return 0
  fi

  local count
  count=$(wc -l < "$fk_add_file")
  log_info "Recreating ${count} FK constraint(s) with NOT VALID..."

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"
  target_psql \
    --set ON_ERROR_STOP=1 \
    -f "$fk_add_file"
  unset PGPASSWORD PGUSER

  rm -f "$fk_add_file"
  log_info "FK constraints recreated."
}

# =============================================================================
# Main
# =============================================================================
main() {
  if [[ "${USE_PROXY:-false}" == "false" ]]; then
    log_info "Starting restore into ${TARGET_DB}@${TARGET_PGHOST:-127.0.0.1}:${TARGET_PGPORT:-5434}"
  else
    log_info "Starting restore into ${TARGET_DB}@${TARGET_PROJECT}:${TARGET_INSTANCE}"
  fi

  if [[ "${MODE:-full_refresh}" != "wipe" \
     && "${MODE:-full_refresh}" != "sync_only" \
     && "${MODE:-full_refresh}" != "drop_tables" \
     && "${MODE:-full_refresh}" != "truncate_tables" ]]; then
    download_dump
  fi

  case "${MODE:-full_refresh}" in
    full_refresh|schema_only)
      recreate_database
      setup_extensions
      setup_owner_role
      ;;
    reload)
      recreate_database
      setup_owner_role
      ;;
    tables_only)
      setup_types "${TABLE_LIST}"
      setup_owner_role

      if [[ "${FK_DEPTH:--1}" != "0" ]]; then
        # =====================================================================
        # FK_DEPTH=-1 path: data-only TRUNCATE (no CASCADE damage)
        # Tables must exist on target (from prior schema_only or full_refresh).
        # Cross-boundary FKs are saved, dropped, and recreated NOT VALID.
        # Views and FKs on non-restored tables are preserved.
        # =====================================================================
        local table_list_csv
        table_list_csv="$(echo "${TABLE_LIST}" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | paste -sd ',' - 2>/dev/null || echo "${TABLE_LIST}")"

        if [[ -n "${SHARED_TABLES_FILE:-}" && -f "$SHARED_TABLES_FILE" ]]; then
          table_list_csv=$(paste -sd ',' "$SHARED_TABLES_FILE" 2>/dev/null || echo "$table_list_csv")
          rm -f "$SHARED_TABLES_FILE"
        fi

        # 1. Save and drop all FKs involving restored tables
        handle_fks "$table_list_csv"

        # 2. TRUNCATE all restored tables (all FKs already dropped — no CASCADE)
        export PGPASSWORD="${DB_PASSWORD:-iam}"
        export PGUSER="${TARGET_DB_USER}"
        local truncate_parts=""
        IFS=',' read -ra trunc_tables <<< "$table_list_csv"
        for table in "${trunc_tables[@]}"; do
          table="$(echo "$table" | xargs)"
          [[ -z "$table" ]] && continue
          truncate_parts="${truncate_parts:+${truncate_parts}, }${TARGET_SCHEMA}.\"${table}\""
        done
        log_info "Truncating restored tables..."
        target_psql --set ON_ERROR_STOP=1 \
          -c "TRUNCATE ${truncate_parts} CASCADE;"
        unset PGPASSWORD PGUSER
        log_info "Tables truncated."

        # Data-only restore runs after this case block.
        # All FKs are recreated there too.
      else
        # =====================================================================
        # FK_DEPTH=0 path: full DDL dump + DROP CASCADE + FK stripping
        # Tables need not exist on target. FK ALTER TABLE statements are
        # stripped from the dump — restored tables have no FK constraints.
        # =====================================================================
        if [[ -n "${SHARED_TABLES_FILE:-}" && -f "$SHARED_TABLES_FILE" ]]; then
          while IFS= read -r table; do
            table="$(echo "$table" | xargs)"
            [[ -z "$table" ]] && continue
            log_info "Dropping table ${TARGET_SCHEMA}.\"${table}\" if exists..."
            export PGPASSWORD="${DB_PASSWORD:-iam}"
            export PGUSER="${TARGET_DB_USER}"
            psql \
              -h "${TARGET_PGHOST}" \
              -p "${TARGET_PGPORT}" \
              -U "${TARGET_DB_USER}" \
              -d "${TARGET_DB}" \
              --set ON_ERROR_STOP=1 \
              -c "DROP TABLE IF EXISTS ${TARGET_SCHEMA}.\"${table}\" CASCADE;"
            unset PGPASSWORD PGUSER
          done < "$SHARED_TABLES_FILE"
          rm -f "$SHARED_TABLES_FILE"
        else
          for table in $(echo "${TABLE_LIST}" | tr ',' ' '); do
            table="$(echo "$table" | xargs)"
            log_info "Dropping table ${TARGET_SCHEMA}.${table} if exists..."
            export PGPASSWORD="${DB_PASSWORD:-iam}"
            export PGUSER="${TARGET_DB_USER}"
            psql \
              -h "${TARGET_PGHOST}" \
              -p "${TARGET_PGPORT}" \
              -U "${TARGET_DB_USER}" \
              -d "${TARGET_DB}" \
              --set ON_ERROR_STOP=1 \
              -c "DROP TABLE IF EXISTS ${TARGET_SCHEMA}.\"${table}\" CASCADE;"
            unset PGPASSWORD PGUSER
          done
        fi
      fi
      ;;
    sync_only)
      [[ "${SYNC_EXTENSIONS:-false}" == "true" ]] && setup_extensions
      [[ "${SYNC_TYPES:-false}" == "true" ]] && sync_all_types
      [[ "${SYNC_SEQUENCES:-false}" == "true" ]] && sync_sequences
      [[ "${SYNC_FUNCTIONS:-false}" == "true" ]] && sync_functions
      ;;
    drop_tables)
      setup_owner_role
      log_info "Dropping tables: ${TABLE_LIST}"
      export PGPASSWORD="${DB_PASSWORD:-iam}"
      export PGUSER="${TARGET_DB_USER}"
      IFS=',' read -ra drop_tables <<< "$TABLE_LIST"
      for table in "${drop_tables[@]}"; do
        table="$(echo "$table" | xargs)"
        [[ -z "$table" ]] && continue
        log_info "Dropping table ${TARGET_SCHEMA}.\"${table}\"..."
        target_psql --set ON_ERROR_STOP=1 \
          -c "DROP TABLE IF EXISTS ${TARGET_SCHEMA}.\"${table}\" CASCADE;"
      done
      unset PGPASSWORD PGUSER
      ;;
    truncate_tables)
      setup_owner_role
      log_info "Truncating tables: ${TABLE_LIST}"
      export PGPASSWORD="${DB_PASSWORD:-iam}"
      export PGUSER="${TARGET_DB_USER}"
      IFS=',' read -ra truncate_tables <<< "$TABLE_LIST"
      for table in "${truncate_tables[@]}"; do
        table="$(echo "$table" | xargs)"
        [[ -z "$table" ]] && continue
        log_info "Truncating table ${TARGET_SCHEMA}.\"${table}\"..."
        target_psql --set ON_ERROR_STOP=1 \
          -c "TRUNCATE TABLE ${TARGET_SCHEMA}.\"${table}\" CASCADE;"
      done
      unset PGPASSWORD PGUSER
      ;;
    wipe)
      recreate_database
      setup_owner_role
      ;;
  esac

  if [[ "${MODE:-full_refresh}" != "wipe" \
     && "${MODE:-full_refresh}" != "sync_only" \
     && "${MODE:-full_refresh}" != "drop_tables" \
     && "${MODE:-full_refresh}" != "truncate_tables" ]]; then
    restore_dump

    # Recreate FK constraints saved during tables_only FK_DEPTH=-1
    if [[ "$MODE" == "tables_only" && "${FK_DEPTH:--1}" != "0" ]]; then
      restore_saved_fks
    fi

    verify_restore
  fi

  log_info "Sandbox database ${TARGET_DB} is ready."
}

main "$@"
