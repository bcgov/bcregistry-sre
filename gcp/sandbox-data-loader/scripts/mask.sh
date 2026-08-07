#!/usr/bin/env bash
# =============================================================================
# scripts/mask.sh — Apply data masking to sandbox database
# =============================================================================
#
# Runs when MASKING_ENABLED=true. Applies masking in this order:
#   1. Enable anon extension in target database
#   2. Parse masking.yaml → generate and apply masking rules
#   3. Download and apply mask.sql from GCS (optional, if it exists)
#
# Reads from:
#   TARGET_DB, TARGET_DB_USER, TARGET_SCHEMA
#   GCS_BUCKET   : bucket containing scripts/mask.sql and masking.yaml
#   MASKING_YAML : path to masking.yaml (default: gs://<GCS_BUCKET>/scripts/masking.yaml)
#                  Can be a local path or a GCS path gs://...
#
# This script can be run independently after a restore:
#   export MASKING_ENABLED=true
#   set -a; source .env; set +a; ./scripts/mask.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/log.sh"

if [[ "${MASKING_ENABLED:-false}" != "true" ]]; then
  log_info "MASKING_ENABLED is not 'true'. Skipping masking."
  exit 0
fi

TARGET_SCHEMA="${TARGET_SCHEMA:-public}"
TARGET_PGHOST="${TARGET_PGHOST:-127.0.0.1}"
TARGET_PGPORT="${TARGET_PGPORT:-5434}"
MASKING_YAML="${MASKING_YAML:-gs://${GCS_BUCKET}/scripts/masking.yaml}"
MASK_SQL_GCS="gs://${GCS_BUCKET}/scripts/mask.sql"

mkdir -p /tmp/loader

# =============================================================================
# Helper: run psql against the TARGET database
# =============================================================================
target_psql() {
  PGPASSWORD="${DB_PASSWORD:-iam}" psql -h "${TARGET_PGHOST}" -p "${TARGET_PGPORT}" -U "${TARGET_DB_USER}" -d "${TARGET_DB}" "$@"
}

# =============================================================================
# Step 1: Enable anon extension
# =============================================================================
enable_anon() {
  log_info "Enabling anon extension in ${TARGET_DB}..."

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  # Extensions MUST be created under a superuser role, because 'anon' installs
  # event triggers and PostgreSQL requires event trigger owners to be
  # superusers. If we CREATE EXTENSION as the pipeline user, the extension
  # and all its member objects (including event triggers) end up owned by
  # that user — and ownership transfer in grant.sh will then fail with
  # 'permission denied to change owner of event trigger ... The owner of an
  # event trigger must be a superuser.'
  #
  # Fix: SET ROLE 'cloudsqlsuperuser' before CREATE EXTENSION so member
  # objects are owned by cloudsqlsuperuser (a superuser). Ownership transfer
  # in grant.sh then leaves them alone because they're not owned by
  # TARGET_DB_USER.
  #
  # Idempotency: if 'anon' already exists but is owned by the pipeline user
  # (leftover from a previous run before this fix), drop and reinstall it
  # under cloudsqlsuperuser. Detected via pg_extension.extowner.
  local anon_owner
  anon_owner=$(target_psql \
    -tAc "SELECT pg_get_userbyid(extowner) FROM pg_extension WHERE extname = 'anon';" \
    2>/dev/null | tr -d '[:space:]')

  if [[ -n "$anon_owner" && "$anon_owner" != "cloudsqlsuperuser" ]]; then
    log_warn "'anon' extension exists but is owned by '${anon_owner}' — dropping and reinstalling as cloudsqlsuperuser..."
    target_psql \
      --set ON_ERROR_STOP=1 \
      -c "DROP EXTENSION IF EXISTS anon CASCADE;"
  fi

  # pgcrypto is required by anon. Install anon under cloudsqlsuperuser
  # (pgcrypto is a no-op IF NOT EXISTS if already present).
  target_psql --set ON_ERROR_STOP=1 <<-'SQL'
    SET ROLE "cloudsqlsuperuser";
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
    CREATE EXTENSION IF NOT EXISTS anon CASCADE;
    SELECT anon.init();
    RESET ROLE;
SQL

  unset PGPASSWORD PGUSER
  log_info "anon extension enabled (owned by cloudsqlsuperuser)."
}

# =============================================================================
# Step 2: Apply masking.yaml rules
# =============================================================================
apply_yaml_masking() {
  # Resolve masking.yaml — local file or download from GCS
  local yaml_path="$MASKING_YAML"

  if [[ "$yaml_path" == gs://* ]]; then
    log_info "Downloading masking.yaml from GCS: ${yaml_path}"
    gcloud storage cp "$yaml_path" "/tmp/loader/masking.yaml"
    yaml_path="/tmp/loader/masking.yaml"
  elif [[ ! -f "$yaml_path" ]]; then
    log_warn "masking.yaml not found at ${yaml_path}. Skipping YAML masking."
    return 0
  fi

  log_info "Generating masking SQL from ${yaml_path}..."

  local generated_sql="/tmp/loader/masking_generated.sql"

  # Parse the flat YAML structure and generate UPDATE statements.
  # Expected format:
  #   tables:
  #     table_name:
  #       col_name: "anon.function()"
  {
    echo "BEGIN;"
    echo ""
  } > "$generated_sql"

  local current_table=""
  local stmts=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Match: "    col_name: value" (4-space indent, key-value)
    if [[ -n "$current_table" && "$line" =~ ^[[:space:]]{4}([^:]+):[[:space:]]+(.*) ]]; then
      local col="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"
      # Strip surrounding quotes from value
      val="${val%\"}"
      val="${val#\"}"
      if [[ "${val^^}" == "NULL" ]]; then
        val="NULL"
      fi
      {
        echo "-- Masking ${current_table}.${col}"
        echo "UPDATE \"${TARGET_SCHEMA}\".\"${current_table}\" SET \"${col}\" = ${val};"
        echo ""
      } >> "$generated_sql"
      stmts=$((stmts + 1))
    # Match: "  table_name:" (2-space indent, key ends with colon)
    elif [[ "$line" =~ ^[[:space:]]{2}([^:]+):$ ]]; then
      current_table="${BASH_REMATCH[1]}"
    fi
  done < "$yaml_path"

  echo "COMMIT;" >> "$generated_sql"

  log_info "Generated ${stmts} masking statement(s) -> ${generated_sql}"

  if [[ -s "${generated_sql}" ]]; then
    log_info "Applying generated masking SQL..."
    export PGPASSWORD="${DB_PASSWORD:-iam}"
    export PGUSER="${TARGET_DB_USER}"
    target_psql \
      --set ON_ERROR_STOP=1 \
      -f "${generated_sql}"
    unset PGPASSWORD PGUSER
    log_info "YAML masking rules applied."
  else
    log_warn "Generated masking SQL is empty — no YAML rules applied."
  fi
}

# =============================================================================
# Step 3: Download and apply mask.sql from GCS (optional)
# =============================================================================
apply_gcs_mask_sql() {
  log_info "Checking for mask.sql in GCS: ${MASK_SQL_GCS}"

  if gcloud storage objects describe "${MASK_SQL_GCS}" >/dev/null 2>&1; then
    log_info "Downloading mask.sql from GCS..."
    gcloud storage cp "${MASK_SQL_GCS}" "/tmp/loader/mask.sql"

    log_info "Applying mask.sql..."
    export PGPASSWORD="${DB_PASSWORD:-iam}"
    export PGUSER="${TARGET_DB_USER}"
    target_psql \
      --set ON_ERROR_STOP=1 \
      -f "/tmp/loader/mask.sql"
    unset PGPASSWORD PGUSER
    log_info "mask.sql applied successfully."
  else
    log_info "No mask.sql found in GCS at ${MASK_SQL_GCS} — skipping."
  fi
}

# =============================================================================
# Main
# =============================================================================
main() {
  log_info "Starting masking phase for ${TARGET_DB}..."

  enable_anon
  apply_yaml_masking
  apply_gcs_mask_sql

  log_info "Masking phase complete."
}

main "$@"
