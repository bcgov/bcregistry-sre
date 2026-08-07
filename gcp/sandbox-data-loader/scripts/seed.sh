#!/usr/bin/env bash
# =============================================================================
# scripts/seed.sh — Inject synthetic data into sandbox database
# =============================================================================
#
# Runs when SEED_DATA_ENABLED=true. Downloads and applies seed SQL files
# from GCS in sorted order. Includes 00_target_backup.sql uploaded by
# seed_target_backup.sh (applied first, before other seed files).
#
# GCS structure expected:
#   gs://<GCS_BUCKET>/scripts/seeds/01_users.sql
#   gs://<GCS_BUCKET>/scripts/seeds/02_orders.sql
#   ...
#
# Seed files should use idempotent inserts:
#   INSERT INTO ... ON CONFLICT DO NOTHING;
#   -- OR --
#   DELETE FROM table WHERE id IN (...); INSERT INTO ...;
#
# Reads from:
#   TARGET_DB, TARGET_DB_USER
#   GCS_BUCKET : bucket containing scripts/seeds/*.sql
#
# This script can be run independently after a restore:
#   export SEED_DATA_ENABLED=true
#   set -a; source .env; set +a; ./scripts/seed.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/log.sh"

if [[ "${SEED_DATA_ENABLED:-false}" != "true" ]]; then
  log_info "SEED_DATA_ENABLED is not 'true'. Skipping seed data injection."
  exit 0
fi

TARGET_PGHOST="${TARGET_PGHOST:-127.0.0.1}"
TARGET_PGPORT="${TARGET_PGPORT:-5434}"

GCS_SEEDS_PATH="gs://${GCS_BUCKET}/scripts/seeds"
LOCAL_SEEDS_DIR="/tmp/loader/seeds"

mkdir -p "${LOCAL_SEEDS_DIR}"

# =============================================================================
# Download seed files from GCS
# =============================================================================
download_seeds() {
  log_info "Downloading seed files from ${GCS_SEEDS_PATH}/..."

  # Check if there are any seed files before attempting download
  if ! gcloud storage ls "${GCS_SEEDS_PATH}/*.sql" &>/dev/null; then
    log_warn "No .sql seed files found at ${GCS_SEEDS_PATH}/. Skipping GCS seed download."
    return 0
  fi

  gcloud storage cp "${GCS_SEEDS_PATH}/*.sql" "${LOCAL_SEEDS_DIR}/"

  local count
  count=$(ls -1 "${LOCAL_SEEDS_DIR}"/*.sql 2>/dev/null | wc -l | tr -d '[:space:]')
  log_info "Downloaded ${count} seed file(s)."
}

# =============================================================================
# Apply seed files in sorted order
# =============================================================================
apply_seeds() {
  local seed_files=()

  # Sort ensures numeric prefix ordering (00_target_backup, 01_, 02_, ...) is respected
  mapfile -t gcs_files < <(ls -1 "${LOCAL_SEEDS_DIR}"/*.sql 2>/dev/null | sort)
  seed_files+=("${gcs_files[@]}")

  # When GCS_BUCKET is empty (local mode), seed_target_backup.sh writes
  # the backup to /tmp/loader/seed_target_upsert.sql — pick it up here.
  if [[ ${#seed_files[@]} -eq 0 && -f "/tmp/loader/seed_target_upsert.sql" ]]; then
    log_info "No GCS seeds — using local backup: /tmp/loader/seed_target_upsert.sql"
    seed_files=("/tmp/loader/seed_target_upsert.sql")
  fi

  if [[ ${#seed_files[@]} -eq 0 ]]; then
    log_warn "No seed files to apply."
    return 0
  fi

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  for seed_file in "${seed_files[@]}"; do
    local filename
    filename="$(basename "${seed_file}")"
    log_info "Applying seed: ${filename}..."

    psql \
      -h "${TARGET_PGHOST}" \
      -p "${TARGET_PGPORT}" \
      -U "${TARGET_DB_USER}" \
      -d "${TARGET_DB}" \
      --set ON_ERROR_STOP=1 \
      -f "${seed_file}"

    log_info "Seed applied: ${filename}"
  done

  unset PGPASSWORD PGUSER
}

# =============================================================================
# Main
# =============================================================================
main() {
  log_info "Starting seed data injection into ${TARGET_DB}..."

  download_seeds
  apply_seeds

  # Cleanup
  rm -rf "${LOCAL_SEEDS_DIR}"

  log_info "Seed data injection complete."
}

main "$@"
