#!/usr/bin/env bash
# =============================================================================
# test/run_tests.sh — Local test runner for sandbox-data-loader
# =============================================================================
#
# Usage:
#   ./test/run_tests.sh                    # run all scenarios
#   ./test/run_tests.sh --list             # list available scenarios
#   ./test/run_tests.sh seed_overwrite     # run one scenario
#   ./test/run_tests.sh seed_overwrite seed_skip  # run two scenarios
#
# Requires:
#   docker compose up -d  (source-db on :5432, target-db on :5434)
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="$(cd "$(dirname "$0")/lib" && pwd)"
SCENARIOS_DIR="$(cd "$(dirname "$0")/scenarios" && pwd)"

# shellcheck source=test/lib/assert.sh
source "${LIB_DIR}/assert.sh"
# shellcheck source=test/lib/db.sh
source "${LIB_DIR}/db.sh"
# shellcheck source=scripts/lib/log.sh
source "${REPO_ROOT}/scripts/lib/log.sh"

# Base env vars — shared with .env.test (connection, auth, flags)
set -a
source "${REPO_ROOT}/.env.test"
set +a

# Track results
_TOTAL=0
_PASSED=0
_FAILED=0
_RUNNER_FAILURES=()

# =============================================================================
# run_pipeline — execute entrypoint.sh with current env
# =============================================================================
run_pipeline() {
  local mode="${1:-tables_only}"
  local table_list="${2:-businesses}"
  local fk_depth="${3:--1}"

  export MODE="$mode"
  export TABLE_LIST="$table_list"
  export FK_DEPTH="$fk_depth"

  # Clear any stale dump from previous runs
  rm -f /tmp/loader/dump_*.sql /tmp/loader/seed_target_upsert.sql /tmp/loader/fk_*.sql /tmp/loader/seed_backup_tmp 2>/dev/null || true

  "${REPO_ROOT}/scripts/entrypoint.sh" 2>&1
}

# =============================================================================
# run_schema_only — bootstrap schema on target from source
# =============================================================================
run_schema_only() {
  log_info "Bootstrapping schema + data on target via full_refresh..."
  run_pipeline "full_refresh" "all" "-1" >/dev/null
  log_info "Schema + data bootstrap complete."
}

# =============================================================================
# run_scenario — execute a single test scenario
# =============================================================================
run_scenario() {
  local scenario_file="$1"
  local scenario_name
  scenario_name="$(basename "$scenario_file" .sh)"

  echo ""
  echo "============================================================================="
  echo " SCENARIO: ${scenario_name}"
  echo "============================================================================="
  echo ""

  reset_assertions

  # Source the scenario — it defines setup() and verify()
  # shellcheck source=/dev/null
  source "$scenario_file"

  # 1. Reset target
  log_info "Resetting target database..."
  target_reset >/dev/null 2>&1

  # 2. Bootstrap schema from source
  run_schema_only

  # 3. Scenario-specific setup (creates divergence)
  log_info "Running scenario setup..."
  setup

  # 4. Run the pipeline with scenario env
  log_info "Running pipeline..."
  if run_pipeline "${SCENARIO_MODE}" "${SCENARIO_TABLE_LIST}" "${SCENARIO_FK_DEPTH:-1}"; then
    log_info "Pipeline completed successfully."
  else
    log_error "Pipeline failed!"
    _fail "pipeline exit code"
    _TOTAL=$(( _TOTAL + 1 ))
    _FAILED=$(( _FAILED + 1 ))
    _RUNNER_FAILURES+=("$scenario_name")
    return 0
  fi

  # 5. Verify assertions
  log_info "Verifying assertions..."
  verify

  # 6. Record results
  local total=$(( _ASSERT_PASS + _ASSERT_FAIL ))
  _TOTAL=$(( _TOTAL + total ))
  if [[ $_ASSERT_FAIL -gt 0 ]]; then
    _PASSED=$(( _PASSED + _ASSERT_PASS ))
    _FAILED=$(( _FAILED + _ASSERT_FAIL ))
    _RUNNER_FAILURES+=("$scenario_name")
  else
    _PASSED=$(( _PASSED + _ASSERT_PASS ))
  fi

  assert_summary
}

# =============================================================================
# List available scenarios
# =============================================================================
list_scenarios() {
  echo "Available scenarios:"
  for f in "${SCENARIOS_DIR}"/*.sh; do
    echo "  $(basename "$f" .sh)"
  done
}

# =============================================================================
# Main
# =============================================================================
main() {
  if [[ "${1:-}" == "--list" ]]; then
    list_scenarios
    exit 0
  fi

  # Ensure Docker is running
  if ! wait_for_source 2>/dev/null; then
    echo "ERROR: source-db not reachable on :5432. Run 'docker compose up -d' first." >&2
    exit 1
  fi
  if ! wait_for_target 2>/dev/null; then
    echo "ERROR: target-db not reachable on :5434. Run 'docker compose up -d' first." >&2
    exit 1
  fi

  local scenarios=()

  if [[ $# -eq 0 ]]; then
    # Run all scenarios
    for f in "${SCENARIOS_DIR}"/*.sh; do
      scenarios+=("$f")
    done
  else
    # Run specified scenarios
    for name in "$@"; do
      local file="${SCENARIOS_DIR}/${name}.sh"
      if [[ ! -f "$file" ]]; then
        echo "ERROR: scenario not found: ${name}" >&2
        list_scenarios
        exit 1
      fi
      scenarios+=("$file")
    done
  fi

  echo ""
  echo "Running ${#scenarios[@]} scenario(s)..."
  echo ""

  for scenario in "${scenarios[@]}"; do
    run_scenario "$scenario" || true
  done

  # Final summary
  echo ""
  echo "============================================================================="
  echo " RESULTS: ${_PASSED} passed, ${_FAILED} failed, ${_TOTAL} total assertions"
  echo "============================================================================="

  if [[ ${#_RUNNER_FAILURES[@]} -gt 0 ]]; then
    echo ""
    echo "Failed scenarios:"
    for name in "${_RUNNER_FAILURES[@]}"; do
      echo "  - ${name}"
    done
    echo ""
    exit 1
  fi

  echo ""
  exit 0
}

main "$@"
