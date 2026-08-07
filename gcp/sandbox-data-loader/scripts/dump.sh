#!/usr/bin/env bash
# =============================================================================
# scripts/dump.sh — Export source (production) database via pg_dump
# =============================================================================
#
# Reads from:
#   SOURCE_PROJECT, SOURCE_REGION, SOURCE_INSTANCE (proxy already running on 5432)
#   SOURCE_DB, SOURCE_DB_USER
#   SOURCE_SCHEMA (optional, default: public)
#   MODE          : full_refresh | schema_only | tables_only
#   TABLE_LIST    : comma-separated table names (required for tables_only)
#   GCS_BUCKET    : destination bucket for the dump file
#   SKIP_EXISTING_DUMP : if "true", skip dump if today's dump exists in GCS
#   FK_DEPTH      : FK dependency depth for tables_only (0=strip+DDL dump, -1=full transitive+data-only)
#
# Outputs:
#   Uploads dump to gs://$GCS_BUCKET/dumps/dump_$TIMESTAMP.sql
#   Exports DUMP_GCS_PATH env var for restore.sh to consume
#
# Why pg_dump over gcloud sql export:
#   - --no-owner       : strip ownership (prod roles don't exist in sandbox)
#   - --no-privileges  : strip GRANT/REVOKE (re-applied cleanly by grant.sh)
#   - --schema-only    : DDL only without touching --table granularity
#   - Per-table -t flags with full quoting control
#   - Schema-scoped exports (--schema=public)
#   - Runs via Cloud SQL Proxy (IAM auth, no public IP needed)
#
# This script can be run independently for testing:
#   set -a; source .env; set +a; ./scripts/dump.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/log.sh"

# =============================================================================
# Configuration & defaults
# =============================================================================
SOURCE_SCHEMA="${SOURCE_SCHEMA:-public}"
SOURCE_PGHOST="${SOURCE_PGHOST:-127.0.0.1}"
SOURCE_PGPORT="${SOURCE_PGPORT:-5432}"
TIMESTAMP="${DUMP_TIMESTAMP:-$(date '+%Y%m%d_%H%M%S')}"
DUMP_FILE="/tmp/loader/dump_${TIMESTAMP}.sql"
DUMP_GCS_PATH="gs://${GCS_BUCKET}/dumps/dump_${TIMESTAMP}.sql"
FK_EXTRA_FILE="/tmp/loader/fk_extra_${TIMESTAMP}.txt"

# Export for restore.sh to pick up (when called from entrypoint)
export DUMP_TIMESTAMP="$TIMESTAMP"
export DUMP_GCS_PATH

mkdir -p /tmp/loader

# =============================================================================
# Idempotency check: skip if dump already exists in GCS
# =============================================================================
check_existing_dump() {
  if [[ "${SKIP_EXISTING_DUMP:-false}" == "true" ]]; then
    log_info "Checking for existing dump in GCS: ${DUMP_GCS_PATH}"
    if gcloud storage objects describe "${DUMP_GCS_PATH}" >/dev/null 2>&1; then
      log_info "Dump already exists at ${DUMP_GCS_PATH}. Skipping dump phase (SKIP_EXISTING_DUMP=true)."
      exit 0
    fi
    log_info "No existing dump found. Proceeding with dump."
  fi
}

# =============================================================================
# Resolve FK-referenced tables (tables_only mode)
# =============================================================================
resolve_fk_deps() {
  local tables="$1"
  local depth="${FK_DEPTH:--1}"

  if [[ "$depth" == "0" || -z "$tables" ]]; then
    return 0
  fi

  log_info "Resolving FK-referenced tables (FK_DEPTH=${depth})..."

  local quoted=""
  IFS=',' read -ra tbl_arr <<< "$tables"
  for t in "${tbl_arr[@]}"; do
    t="$(echo "$t" | xargs)"
    quoted="${quoted:+${quoted},}'${t}'"
  done

  psql -h "${SOURCE_PGHOST}" -p "${SOURCE_PGPORT}" -U "${SOURCE_DB_USER}" -d "${SOURCE_DB}" \
    --tuples-only --no-align -c "
    WITH RECURSIVE fk_deps AS (
      SELECT c.oid, c.relname, 0 AS depth, ARRAY[c.oid] AS visited
      FROM pg_class c
      JOIN pg_namespace n ON c.relnamespace = n.oid
      WHERE n.nspname = '${SOURCE_SCHEMA}'
        AND c.relkind = 'r'
        AND c.relname IN (${quoted})
      UNION
      SELECT ref.oid, ref.relname, d.depth + 1, d.visited || ref.oid
      FROM fk_deps d
      JOIN pg_class c ON c.oid = d.oid
      JOIN pg_constraint fk ON fk.conrelid = c.oid
      JOIN pg_class ref ON ref.oid = fk.confrelid
      JOIN pg_namespace n ON ref.relnamespace = n.oid
      WHERE n.nspname = '${SOURCE_SCHEMA}'
        AND fk.contype = 'f'
        AND NOT (ref.oid = ANY(d.visited))
        AND (${depth} = -1 OR d.depth < ${depth})
    )
    SELECT relname FROM fk_deps WHERE depth > 0;
  " > "$FK_EXTRA_FILE"

  if [[ -s "$FK_EXTRA_FILE" ]]; then
    local count fk_list
    count=$(wc -l < "$FK_EXTRA_FILE")
    fk_list=$(tr '\n' ' ' < "$FK_EXTRA_FILE")
    log_info "Found ${count} FK-referenced table(s): ${fk_list}"
  else
    log_info "No additional FK-referenced tables found."
    rm -f "$FK_EXTRA_FILE"
  fi
}

# =============================================================================
# Build pg_dump arguments based on MODE
# =============================================================================
build_pg_dump_args() {
  local -a args=(
    -h "${SOURCE_PGHOST}"
    -p "${SOURCE_PGPORT}"
    -U "${SOURCE_DB_USER}"
    -d "${SOURCE_DB}"
    # Do not restore ownership — source and target may have different user sets.
    # Prod IAM users should not be replicated into sandbox.
    --no-owner
    # Do not restore GRANT/REVOKE — grants will be reapplied by grant.sh
    # with sandbox-appropriate permissions.
    --no-privileges
    --format=plain
    --verbose
    --file="${DUMP_FILE}"
    # Scope export to the configured schema only
    --schema="${SOURCE_SCHEMA}"
  )

  case "$MODE" in
    schema_only)
      # Schema only: tables, views, functions, sequences — no row data
      args+=(--schema-only)
      log_info "Mode: schema_only — dumping DDL only (no row data)" >&2
      ;;
    tables_only)
      # Specific tables only. TABLE_LIST is comma-separated.
      # One -t flag per table so pg_dump handles schema-qualified quoting correctly.
      IFS=',' read -ra tables <<< "$TABLE_LIST"
      for table in "${tables[@]}"; do
        table="$(echo "$table" | xargs)"  # trim whitespace
        args+=(-t "${SOURCE_SCHEMA}.${table}")
      done
      # Add FK-referenced tables from resolve_fk_deps
      if [[ -f "$FK_EXTRA_FILE" ]]; then
        while IFS= read -r fk_table; do
          [[ -n "$fk_table" ]] && args+=(-t "${SOURCE_SCHEMA}.${fk_table}")
        done < "$FK_EXTRA_FILE"
        rm -f "$FK_EXTRA_FILE"
      fi
      # Data-only when FK_DEPTH=-1 (DDL not needed — tables exist from schema_only).
      # FK_DEPTH=0 keeps full DDL so FK ALTER TABLE can be stripped during restore.
      if [[ "${FK_DEPTH:--1}" != "0" ]]; then
        args+=(--data-only)
      fi
      log_info "Mode: tables_only — tables: ${TABLE_LIST}" >&2
      ;;
    full_refresh)
      # Full dump: schema + all data
      log_info "Mode: full_refresh — dumping schema and all data" >&2
      ;;
  esac

  printf '%s\n' "${args[@]}"
}

# =============================================================================
# Main dump logic
# =============================================================================
main() {
  log_info "Starting dump from ${SOURCE_DB}@${SOURCE_PGHOST}:${SOURCE_PGPORT}"

  check_existing_dump

  # Password authentication:
  # - Cloud SQL Proxy (--auto-iam-authn): PGPASSWORD="iam" is a sentinel; proxy handles auth via ADC.
  # - Local Docker PostgreSQL: PGPASSWORD must be the real database password.
  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${SOURCE_DB_USER}"

  # Resolve FK dependencies before building pg_dump args
  if [[ "$MODE" == "tables_only" && "${FK_DEPTH:--1}" != "0" ]]; then
    resolve_fk_deps "$TABLE_LIST"
  fi

  # Write all tables to be restored into a shared file for restore.sh.
  # This ensures restore.sh can drop FK-referenced tables (not just TABLE_LIST)
  # before restore, preventing "already exists" errors and data duplication.
  SHARED_TABLES_FILE="/tmp/loader/all_restore_tables_${TIMESTAMP}.txt"
  if [[ "$MODE" == "tables_only" ]]; then
    echo "$TABLE_LIST" | tr ',' '\n' | sed 's/^ *//;s/ *$//' > "$SHARED_TABLES_FILE"
    if [[ -f "$FK_EXTRA_FILE" && -s "$FK_EXTRA_FILE" ]]; then
      cat "$FK_EXTRA_FILE" >> "$SHARED_TABLES_FILE"
    fi
    log_info "Restore tables written to shared file: $(wc -l < "${SHARED_TABLES_FILE}") table(s)"
  fi

  log_info "Running pg_dump..."

  # Read args into array (one per line from build_pg_dump_args)
  mapfile -t pg_args < <(build_pg_dump_args)
  pg_dump "${pg_args[@]}"

  # Immediately clear credential variables after use
  unset PGPASSWORD PGUSER

  local dump_size
  dump_size=$(du -sh "${DUMP_FILE}" | cut -f1)
  log_info "Dump complete — size: ${dump_size}, file: ${DUMP_FILE}"

  # =============================================================================
  # Upload to GCS (skipped when GCS_BUCKET is not set — local testing)
  # =============================================================================
  if [[ -n "${GCS_BUCKET:-}" ]]; then
    log_info "Uploading dump to ${DUMP_GCS_PATH}..."
    gcloud storage cp --content-type=application/x-sql "${DUMP_FILE}" "${DUMP_GCS_PATH}"
    log_info "Upload complete: ${DUMP_GCS_PATH}"
    # Remove local dump file — GCS is the source of truth; saves container disk
    rm -f "${DUMP_FILE}"
    log_info "Local dump file removed."
  else
    log_info "GCS_BUCKET not set — keeping local dump at ${DUMP_FILE}"
    export DUMP_GCS_PATH="${DUMP_FILE}"
  fi
}

main "$@"
