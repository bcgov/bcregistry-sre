#!/usr/bin/env bash
# =============================================================================
# scripts/entrypoint.sh — Main orchestrator for the GCP Sandbox Database Loader
# =============================================================================
#
# This script is the Cloud Run Job entrypoint. It:
#   1. Validates all required environment variables
#   2. Enforces safety checks (prevents accidental prod overwrites)
#   3. Starts Cloud SQL Proxy for source (port 5432) and target (port 5433)
#      using Application Default Credentials + --auto-iam-authn
#   4. Orchestrates the pipeline: [seed_backup] → dump → restore → [mask] → [seed] → grant
#   5. Cleans up proxies on any exit (trap EXIT)
#
# Usage (Cloud Run Job):
#   Set env vars via Cloud Run Job configuration or Secret Manager references.
#
# Usage (local development):
#   gcloud auth application-default login
#   set -a; source .env; set +a # fill in your values
#   ./scripts/entrypoint.sh
#
# For local Docker PostgreSQL (no proxy):
#   docker compose up -d
#   set -a; source .env.test; set +a
#   ./scripts/entrypoint.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/log.sh"

# =============================================================================
# 1. Environment variable validation
# =============================================================================
validate_env() {
  log_section "Validating environment"

  local required_vars=(
    SOURCE_PROJECT
    SOURCE_REGION
    SOURCE_INSTANCE
    SOURCE_DB
    SOURCE_DB_USER
    TARGET_PROJECT
    TARGET_REGION
    TARGET_INSTANCE
    TARGET_DB
    TARGET_DB_USER
    GCS_BUCKET
    MODE
  )

  # When USE_PROXY=false (local databases), GCS_BUCKET and GCP-specific vars are optional
  if [[ "${USE_PROXY:-false}" == "false" ]]; then
    local skip_vars=(GCS_BUCKET SOURCE_PROJECT SOURCE_REGION SOURCE_INSTANCE TARGET_PROJECT TARGET_REGION TARGET_INSTANCE)
    local filtered=()
    for var in "${required_vars[@]}"; do
      local skip=false
      for sv in "${skip_vars[@]}"; do
        [[ "$var" == "$sv" ]] && skip=true && break
      done
      [[ "$skip" == "false" ]] && filtered+=("$var")
    done
    required_vars=("${filtered[@]}")
  fi

  local missing=()
  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      missing+=("$var")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Missing required environment variables: ${missing[*]}"
  fi

  # Validate MODE
  case "$MODE" in
    full_refresh|schema_only|tables_only|sync_only|wipe|reload|drop_tables|truncate_tables|post_process) ;;
    *) die "Invalid MODE='${MODE}'. Must be one of: full_refresh, schema_only, tables_only, sync_only, wipe, reload, drop_tables, truncate_tables, post_process" ;;
  esac

  # tables_only requires TABLE_LIST
  if [[ "$MODE" == "tables_only" ]] && [[ -z "${TABLE_LIST:-}" ]]; then
    die "MODE=tables_only requires TABLE_LIST (comma-separated table names)"
  fi

  # sync_only requires at least one sync flag enabled
  if [[ "$MODE" == "sync_only" ]]; then
    if [[ "${SYNC_TYPES:-false}" != "true" \
       && "${SYNC_FUNCTIONS:-false}" != "true" \
       && "${SYNC_EXTENSIONS:-false}" != "true" \
       && "${SYNC_SEQUENCES:-false}" != "true" ]]; then
      die "MODE=sync_only requires at least one of: SYNC_TYPES=true, SYNC_FUNCTIONS=true, SYNC_EXTENSIONS=true, SYNC_SEQUENCES=true"
    fi
  fi

  # drop_tables and truncate_tables require TABLE_LIST
  if [[ "$MODE" == "drop_tables" || "$MODE" == "truncate_tables" ]] && [[ -z "${TABLE_LIST:-}" ]]; then
    die "MODE=${MODE} requires TABLE_LIST (comma-separated table names)"
  fi

  log_info "All required environment variables present."
  log_info "USE_PROXY=${USE_PROXY:-false}"
  log_info "MODE=${MODE}"
  log_info "MASKING_ENABLED=${MASKING_ENABLED:-false}"
  log_info "SEED_DATA_ENABLED=${SEED_DATA_ENABLED:-false}"
  log_info "FK_DEPTH=${FK_DEPTH:-1}"
  log_info "SYNC_TYPES=${SYNC_TYPES:-false}"
  log_info "SYNC_FUNCTIONS=${SYNC_FUNCTIONS:-false}"
  log_info "SYNC_EXTENSIONS=${SYNC_EXTENSIONS:-false}"
  log_info "SYNC_SEQUENCES=${SYNC_SEQUENCES:-false}"
}

# =============================================================================
# 2. Safety checks
# =============================================================================
safety_checks() {
  log_section "Safety checks"

  # When connecting to local databases, skip GCP-specific safety checks
  if [[ "${USE_PROXY:-false}" == "false" ]]; then
    log_info "USE_PROXY=false — skipping GCP safety checks."
    log_info "Target: ${TARGET_DB}@${TARGET_PGHOST:-127.0.0.1}:${TARGET_PGPORT:-5434}"
    return 0
  fi

  # Prevent accidental writes to production-named instances.
  # Any instance or project containing "prod" in its name requires
  # explicit override via ALLOW_PROD_TARGET=true.
  local target_str="${TARGET_PROJECT}:${TARGET_INSTANCE}:${TARGET_DB}"
  if echo "$target_str" | grep -qi "prod"; then
    if [[ "${ALLOW_PROD_TARGET:-false}" != "true" ]]; then
      die "TARGET appears to be a production resource (contains 'prod'): ${target_str}. " \
          "Set ALLOW_PROD_TARGET=true to override (use with extreme caution)."
    else
      log_warn "ALLOW_PROD_TARGET=true — writing to what appears to be a production target: ${target_str}"
    fi
  fi

  log_info "Safety checks passed. Target: ${TARGET_PROJECT}:${TARGET_REGION}:${TARGET_INSTANCE}/${TARGET_DB}"
}

# =============================================================================
# 3. Cloud SQL Proxy management
# =============================================================================
SOURCE_PROXY_PID=""
TARGET_PROXY_PID=""

needs_source_proxy() {
  case "$MODE" in
    full_refresh|schema_only|tables_only|sync_only) return 0 ;;
    *) return 1 ;;
  esac
}

should_skip_proxy() {
  [[ "${USE_PROXY:-false}" == "false" ]]
}

start_proxies() {
  log_section "Starting Cloud SQL Proxies"

  if should_skip_proxy; then
    log_info "USE_PROXY=false — skipping proxy startup (expected when connecting to local databases)."
    return 0
  fi

  # Target proxy — port 5433 (always needed — all modes write to target)
  log_info "Starting target proxy: ${TARGET_PROJECT}:${TARGET_REGION}:${TARGET_INSTANCE} → localhost:5433"
  cloud-sql-proxy \
    "${TARGET_PROJECT}:${TARGET_REGION}:${TARGET_INSTANCE}" \
    --port 5433 \
    --auto-iam-authn \
    --structured-logs \
    &
  TARGET_PROXY_PID=$!

  # Source proxy — port 5432 (only needed when the mode queries the source)
  if needs_source_proxy; then
    # --auto-iam-authn: enables automatic IAM database authentication.
    # This means pg_dump/psql authenticate as the IAM service account user
    # rather than requiring a password. The proxy intercepts the connection
    # and exchanges the ADC token for a short-lived DB credential.
    log_info "Starting source proxy: ${SOURCE_PROJECT}:${SOURCE_REGION}:${SOURCE_INSTANCE} → localhost:5432"
    cloud-sql-proxy \
      "${SOURCE_PROJECT}:${SOURCE_REGION}:${SOURCE_INSTANCE}" \
      --port 5432 \
      --auto-iam-authn \
      --structured-logs \
      &
    SOURCE_PROXY_PID=$!
  else
    log_info "Source proxy not needed (MODE=${MODE}) — skipping."
  fi

  # Allow proxies time to establish secure tunnels
  log_info "Waiting for proxies to initialize..."
  sleep 8

  # Verify target proxy is running
  kill -0 "$TARGET_PROXY_PID" 2>/dev/null \
    || die "Target Cloud SQL Proxy (PID ${TARGET_PROXY_PID}) failed to start."

  if [[ -n "$SOURCE_PROXY_PID" ]]; then
    kill -0 "$SOURCE_PROXY_PID" 2>/dev/null \
      || die "Source Cloud SQL Proxy (PID ${SOURCE_PROXY_PID}) failed to start."
    log_info "Both proxies running. Source PID=${SOURCE_PROXY_PID}, Target PID=${TARGET_PROXY_PID}"
  else
    log_info "Target proxy running (PID=${TARGET_PROXY_PID}) — source proxy not required."
  fi

  # Override ports so child scripts (restore.sh, mask.sh, seed.sh) connect
  # through the Cloud SQL Proxy instead of Docker Compose containers.
  export TARGET_PGPORT=5433
  [[ -n "$SOURCE_PROXY_PID" ]] && export SOURCE_PGPORT=5432 || true
}

stop_proxies() {
  if should_skip_proxy; then
    log_info "USE_PROXY=false — no proxies to stop."
    return 0
  fi
  log_info "Stopping Cloud SQL Proxies..."
  [[ -n "$SOURCE_PROXY_PID" ]] && kill "$SOURCE_PROXY_PID" 2>/dev/null || true
  [[ -n "$TARGET_PROXY_PID" ]] && kill "$TARGET_PROXY_PID" 2>/dev/null || true
}

# =============================================================================
# 4. Pipeline orchestration
# =============================================================================
run_pipeline() {
  local job_start
  job_start=$(date +%s)

  log_section "Starting pipeline"
  if [[ "${USE_PROXY:-false}" == "false" ]]; then
    log_info "Source: ${SOURCE_DB}@${SOURCE_PGHOST:-127.0.0.1}:${SOURCE_PGPORT:-5432}"
    log_info "Target: ${TARGET_DB}@${TARGET_PGHOST:-127.0.0.1}:${TARGET_PGPORT:-5434}"
  else
    log_info "Source: ${SOURCE_PROJECT}:${SOURCE_REGION}:${SOURCE_INSTANCE}/${SOURCE_DB}"
    log_info "Target: ${TARGET_PROJECT}:${TARGET_REGION}:${TARGET_INSTANCE}/${TARGET_DB}"
  fi

  # Set a unified timestamp for the entire pipeline run so dump and restore
  # agree on the GCS path without needing to pass variables back from child scripts.
  export DUMP_TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

  # Clear any stale DUMP_GCS_PATH for modes that generate their own dump.
  # reload skips dump.sh and uses an explicit path (or falls back to the latest dump in GCS).
  if [[ "$MODE" != "reload" ]]; then
    unset DUMP_GCS_PATH
  fi

  # --- BACKUP TARGET SEED DATA (before restore overwrites target tables) ---
  # Only for modes that replace data without recreating the database.
  # full_refresh intentionally wipes sandbox-specific data.
  if [[ -n "${SEED_FROM_TARGET_TABLES:-}" \
     && "${SEED_DATA_ENABLED:-false}" == "true" \
     && ( "$MODE" == "tables_only" || "$MODE" == "reload" ) ]]; then
    log_section "Phase: Backup Target Seed Data"
    local backup_start
    backup_start=$(date +%s)
    "${SCRIPT_DIR}/seed_target_backup.sh"
    log_end "Backup Target Seed Data" $(( $(date +%s) - backup_start ))
  fi

  if [[ "$MODE" == "sync_only" || "$MODE" == "wipe" || "$MODE" == "reload" \
     || "$MODE" == "drop_tables" || "$MODE" == "truncate_tables" \
     || "$MODE" == "post_process" ]]; then
    log_info "Mode: ${MODE} — skipping dump phase."
  else
    # --- DUMP ---
    log_section "Phase: Dump"
    local dump_start
    dump_start=$(date +%s)
    "${SCRIPT_DIR}/dump.sh"
    log_end "Dump" $(( $(date +%s) - dump_start ))
  fi

  # --- RESTORE (skipped for post_process) ---
  if [[ "$MODE" != "post_process" ]]; then
    log_section "Phase: Restore"
    local restore_start
    restore_start=$(date +%s)
    "${SCRIPT_DIR}/restore.sh"
    log_end "Restore" $(( $(date +%s) - restore_start ))
  else
    log_info "Mode: post_process — skipping restore phase."
  fi

  # Post-processing (mask, seed, grants) only makes sense when tables exist.
  if [[ "$MODE" != "sync_only" && "$MODE" != "wipe" \
     && "$MODE" != "drop_tables" && "$MODE" != "truncate_tables" ]]; then
    # --- MASKING (optional) ---
    if [[ "${MASKING_ENABLED:-false}" == "true" ]]; then
      log_section "Phase: Masking"
      local mask_start
      mask_start=$(date +%s)
      "${SCRIPT_DIR}/mask.sh"
      log_end "Masking" $(( $(date +%s) - mask_start ))
    else
      log_info "Skipping masking (MASKING_ENABLED=false)"
    fi

    # --- SEED DATA (optional) ---
    if [[ "${SEED_DATA_ENABLED:-false}" == "true" ]]; then
      log_section "Phase: Seed Data"
      local seed_start
      seed_start=$(date +%s)
      "${SCRIPT_DIR}/seed.sh"
      log_end "Seed Data" $(( $(date +%s) - seed_start ))
    else
      log_info "Skipping seed data (SEED_DATA_ENABLED=false)"
    fi

    # --- GRANTS ---
    log_section "Phase: Grants"
    local grant_start
    grant_start=$(date +%s)
    "${SCRIPT_DIR}/grant.sh"
    log_end "Grants" $(( $(date +%s) - grant_start ))
  else
    log_info "Skipping post-processing (mask/seed/grants) in ${MODE} mode."
  fi

  log_end "Total job" $(( $(date +%s) - job_start ))
  log_info "Database refresh complete. Sandbox is ready."
}

# =============================================================================
# Main
# =============================================================================
main() {
  # Trap EXIT to ensure proxies are always cleaned up, even on error.
  # This prevents orphaned proxy processes in the container.
  trap stop_proxies EXIT

  validate_env
  safety_checks
  start_proxies
  run_pipeline
}

main "$@"
