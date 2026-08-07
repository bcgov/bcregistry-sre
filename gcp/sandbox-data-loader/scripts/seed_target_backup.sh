#!/usr/bin/env bash
# =============================================================================
# scripts/seed_target_backup.sh — Backup target tables for upsert seeding
# =============================================================================
#
# Backs up specific tables from the TARGET database before the restore phase,
# so their rows can be upserted back after prod data replaces them.
#
# Reads from:
#   TARGET_DB, TARGET_DB_USER, TARGET_SCHEMA
#   SEED_FROM_TARGET_TABLES : comma-separated table names
#   SEED_CONFLICT_MODE      : skip (default) | overwrite
#   GCS_BUCKET              : bucket for uploading the backup file
#
# Outputs:
#   /tmp/loader/seed_target_upsert.sql — idempotent INSERT statements
#
# Gated in entrypoint.sh to only run for tables_only and reload modes
# (not full_refresh, which intentionally wipes sandbox-specific data).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/log.sh"

TARGET_SCHEMA="${TARGET_SCHEMA:-public}"
TARGET_PGHOST="${TARGET_PGHOST:-127.0.0.1}"
TARGET_PGPORT="${TARGET_PGPORT:-5434}"
SEED_CONFLICT_MODE="${SEED_CONFLICT_MODE:-skip}"
OUTPUT_FILE="/tmp/loader/seed_target_upsert.sql"
TEMP_DIR="/tmp/loader/seed_backup_tmp"

if [[ -z "${SEED_FROM_TARGET_TABLES:-}" ]]; then
  log_info "SEED_FROM_TARGET_TABLES not set — nothing to backup."
  exit 0
fi

mkdir -p "$TEMP_DIR"
rm -f "$OUTPUT_FILE"

export PGPASSWORD="${DB_PASSWORD:-iam}"
export PGUSER="${TARGET_DB_USER}"

backup_table() {
  local table="$1"
  local schema_table="${TARGET_SCHEMA}.${table}"
  local dump_file="${TEMP_DIR}/${table}.sql"

  log_info "Backing up ${schema_table}..."

  pg_dump \
    -h "${TARGET_PGHOST}" -p "${TARGET_PGPORT}" \
    -U "${TARGET_DB_USER}" \
    -d "${TARGET_DB}" \
    --data-only \
    --column-inserts \
    -t "${schema_table}" \
    --no-owner \
    --no-privileges \
    -f "$dump_file" \
    2>/dev/null || {
    log_warn "Failed to dump ${schema_table} — skipping"
    return
  }

  if [[ ! -s "$dump_file" ]]; then
    log_info "${schema_table} is empty — nothing to backup"
    rm -f "$dump_file"
    return
  fi

  local row_count=0

  case "$SEED_CONFLICT_MODE" in
    overwrite)
      local pk_cols
      pk_cols=$(psql -h "${TARGET_PGHOST}" -p "${TARGET_PGPORT}" -U "${TARGET_DB_USER}" -d "${TARGET_DB}" \
        --tuples-only --no-align \
        -c "SELECT string_agg(quote_ident(k.column_name), ', ' ORDER BY k.ordinal_position)
            FROM information_schema.table_constraints t
            JOIN information_schema.key_column_usage k
              ON t.constraint_name = k.constraint_name
             AND t.constraint_schema = k.constraint_schema
            WHERE t.constraint_type = 'PRIMARY KEY'
              AND t.table_schema = '${TARGET_SCHEMA}'
              AND t.table_name = '${table}';" 2>/dev/null || true)

      if [[ -z "$pk_cols" ]]; then
        log_warn "No PK found for ${schema_table} — falling back to ON CONFLICT DO NOTHING"
        while IFS= read -r line; do
          if [[ "$line" =~ ^INSERT ]]; then
            echo "${line%;} ON CONFLICT DO NOTHING;"
          else
            echo "$line"
          fi
        done < "$dump_file" >> "$OUTPUT_FILE"
      else
        local set_all_cols
        set_all_cols=$(psql -h "${TARGET_PGHOST}" -p "${TARGET_PGPORT}" -U "${TARGET_DB_USER}" -d "${TARGET_DB}" \
          --tuples-only --no-align \
          -c "SELECT string_agg(format('%I = EXCLUDED.%I', column_name, column_name), ', ' ORDER BY ordinal_position)
              FROM information_schema.columns
              WHERE table_schema = '${TARGET_SCHEMA}' AND table_name = '${table}';" 2>/dev/null || true)

        local suffix=" ON CONFLICT (${pk_cols}) DO UPDATE SET ${set_all_cols};"
        while IFS= read -r line; do
          if [[ "$line" =~ ^INSERT ]]; then
            echo "${line%;}${suffix}"
          else
            echo "$line"
          fi
        done < "$dump_file" >> "$OUTPUT_FILE"
      fi
      ;;
    *)
      while IFS= read -r line; do
        if [[ "$line" =~ ^INSERT ]]; then
          echo "${line%;} ON CONFLICT DO NOTHING;"
        else
          echo "$line"
        fi
      done < "$dump_file" >> "$OUTPUT_FILE"
      ;;
  esac

  row_count=$(grep -c '^INSERT' "$dump_file" || true)
  rm -f "$dump_file"
  log_info "Backed up ${row_count} row(s) from ${schema_table} (mode: ${SEED_CONFLICT_MODE})"
}

IFS=',' read -ra TABLES <<< "$SEED_FROM_TARGET_TABLES"
for table in "${TABLES[@]}"; do
  table="$(echo "$table" | xargs)"
  [[ -z "$table" ]] && continue
  backup_table "$table"
done

unset PGPASSWORD PGUSER
rm -rf "$TEMP_DIR"

if [[ ! -s "$OUTPUT_FILE" ]]; then
  rm -f "$OUTPUT_FILE"
  log_info "No rows backed up from any table."
  exit 0
fi

total_rows=$(grep -c '^INSERT' "$OUTPUT_FILE" || true)
log_info "Total: ${total_rows} seed row(s) written to ${OUTPUT_FILE}"

if [[ -n "${GCS_BUCKET:-}" ]]; then
  gcs_path="gs://${GCS_BUCKET}/scripts/seeds/00_target_backup.sql"
  log_info "Uploading seed backup to ${gcs_path}..."
  gcloud storage cp "$OUTPUT_FILE" "$gcs_path" || log_warn "Failed to upload seed backup to GCS (non-fatal)"
else
  log_info "GCS_BUCKET not set — skipping upload of seed backup to GCS."
fi
