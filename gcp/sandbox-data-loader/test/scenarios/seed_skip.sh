#!/usr/bin/env bash
# =============================================================================
# test/scenarios/seed_skip.sh — SEED_CONFLICT_MODE=skip
# =============================================================================
#
# Scenario: Target has custom data that differs from source.
#           skip mode should let source data win on conflicts,
#           but still insert target-only rows.
#
# Setup:
#   - Modify CEO/CFO descriptions in office_types
#   - Add SANDBOX_CORP row to corp_types (VARCHAR PK, no enum constraint)
#
# Expected after pipeline:
#   - CEO  = "Chief Executive Officer" (conflict → DO NOTHING → source wins)
#   - CFO  = "Chief Financial Officer" (conflict → DO NOTHING → source wins)
#   - SANDBOX_CORP = "Sandbox Corp" (no conflict, inserted)
#   - businesses and filings restored from source
# =============================================================================

export SCENARIO_MODE="tables_only"
export SCENARIO_TABLE_LIST="businesses,office_types,corp_types"
export SCENARIO_FK_DEPTH="-1"
export SEED_FROM_TARGET_TABLES="office_types,corp_types"
export SEED_CONFLICT_MODE="skip"

setup() {
  target_psql -c "
    UPDATE public.office_types SET description = 'Modified by Sandbox' WHERE code = 'CEO';
    UPDATE public.office_types SET description = 'Modified CFO' WHERE code = 'CFO';
  " >/dev/null

  target_psql -c "
    INSERT INTO public.corp_types (code, description)
    VALUES ('SC', 'Sandbox Corp');
  " >/dev/null

  local ceo_desc
  ceo_desc=$(target_psql --tuples-only --no-align \
    -c "SELECT description FROM public.office_types WHERE code = 'CEO';")
  if [[ "$ceo_desc" != "Modified by Sandbox" ]]; then
    echo "SETUP FAILED: CEO description not modified (got: ${ceo_desc})" >&2
    return 1
  fi
}

verify() {
  # Conflicting rows: source data wins (DO NOTHING skips upsert)
  assert_cell "public.office_types" "code = 'CEO'" "description" "Chief Executive Officer"
  assert_cell "public.office_types" "code = 'CFO'" "description" "Chief Financial Officer"

  # Target-only row: no conflict → inserted
  assert_cell "public.corp_types" "code = 'SC'" "description" "Sandbox Corp"

  # Other source rows intact
  assert_cell "public.office_types" "code = 'DIRECTOR'" "description" "Director"
  assert_cell "public.office_types" "code = 'REGISTERED_AGENT'" "description" "Registered Agent"
  assert_cell "public.office_types" "code = 'SECRETARY'" "description" "Corporate Secretary"

  # Total office_types: 5 source rows
  assert_row_count "public.office_types" "5"

  # Data tables restored correctly
  assert_row_count "public.businesses" "5"
  assert_row_count "public.filings" "6"
}
