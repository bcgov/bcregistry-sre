#!/usr/bin/env bash
# =============================================================================
# test/scenarios/seed_multi_table.sh — Multiple tables in SEED_FROM_TARGET_TABLES
# =============================================================================
#
# Scenario: Back up and restore data from multiple tables simultaneously.
#
# Setup:
#   - Modify CEO description in office_types
#   - Add SANDBOX_CORP to corp_types
#
# Expected after pipeline:
#   - Both custom data preserved via overwrite upsert
#   - Both source-only rows intact
# =============================================================================

export SCENARIO_MODE="tables_only"
export SCENARIO_TABLE_LIST="businesses,office_types,corp_types"
export SCENARIO_FK_DEPTH="-1"
export SEED_FROM_TARGET_TABLES="office_types,corp_types"
export SEED_CONFLICT_MODE="overwrite"

setup() {
  target_psql -c "
    UPDATE public.office_types SET description = 'Sandbox CEO' WHERE code = 'CEO';
    INSERT INTO public.corp_types (code, description)
    VALUES ('SC', 'Sandbox Corp');
  " >/dev/null

  local ot_desc
  ot_desc=$(target_psql --tuples-only --no-align \
    -c "SELECT description FROM public.office_types WHERE code = 'CEO';")
  local ct_count
  ct_count=$(target_psql --tuples-only --no-align \
    -c "SELECT count(*) FROM public.corp_types WHERE code = 'SC';")
  if [[ "$ot_desc" != "Sandbox CEO" || "$ct_count" != "1" ]]; then
    echo "SETUP FAILED: custom data not applied" >&2
    return 1
  fi
}

verify() {
  # office_types: modified row preserved
  assert_cell "public.office_types" "code = 'CEO'" "description" "Sandbox CEO"
  assert_cell "public.office_types" "code = 'CFO'" "description" "Chief Financial Officer"

  # corp_types: custom row preserved
  assert_cell "public.corp_types" "code = 'SC'" "description" "Sandbox Corp"

  # Row counts
  assert_row_count "public.office_types" "5"
  assert_row_count "public.businesses" "5"
  assert_row_count "public.filings" "6"
}
