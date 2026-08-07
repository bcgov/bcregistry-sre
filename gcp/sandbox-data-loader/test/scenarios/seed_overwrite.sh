#!/usr/bin/env bash
# =============================================================================
# test/scenarios/seed_overwrite.sh — SEED_CONFLICT_MODE=overwrite
# =============================================================================
#
# Scenario: Target has custom data that differs from source.
#           overwrite mode should preserve target's pre-restore data.
#
# Setup:
#   - Modify CEO/CFO descriptions in office_types
#   - Add SANDBOX_CORP row to corp_types (VARCHAR PK, no enum constraint)
#
# Expected after pipeline:
#   - CEO  = "Modified by Sandbox"  (upsert overwrites source's value)
#   - CFO  = "Modified CFO"         (upsert overwrites source's value)
#   - SANDBOX_CORP = "Sandbox Corp" (no conflict, inserted)
#   - businesses and filings restored from source
# =============================================================================

export SCENARIO_MODE="tables_only"
export SCENARIO_TABLE_LIST="businesses,office_types,corp_types"
export SCENARIO_FK_DEPTH="-1"
export SEED_FROM_TARGET_TABLES="office_types,corp_types"
export SEED_CONFLICT_MODE="overwrite"

setup() {
  # Modify shared rows on target (valid enum values)
  target_psql -c "
    UPDATE public.office_types SET description = 'Modified by Sandbox' WHERE code = 'CEO';
    UPDATE public.office_types SET description = 'Modified CFO' WHERE code = 'CFO';
  " >/dev/null

  # Add target-only row to corp_types (VARCHAR PK, no enum constraint)
  target_psql -c "
    INSERT INTO public.corp_types (code, description)
    VALUES ('SC', 'Sandbox Corp');
  " >/dev/null

  # Verify setup took effect
  local ceo_desc
  ceo_desc=$(target_psql --tuples-only --no-align \
    -c "SELECT description FROM public.office_types WHERE code = 'CEO';")
  if [[ "$ceo_desc" != "Modified by Sandbox" ]]; then
    echo "SETUP FAILED: CEO description not modified (got: ${ceo_desc})" >&2
    return 1
  fi
}

verify() {
  # Modified shared rows should survive (upserted back after restore)
  assert_cell "public.office_types" "code = 'CEO'" "description" "Modified by Sandbox"
  assert_cell "public.office_types" "code = 'CFO'" "description" "Modified CFO"

  # Source-only rows should still exist (restored from dump, not in backup)
  assert_cell "public.office_types" "code = 'DIRECTOR'" "description" "Director"
  assert_cell "public.office_types" "code = 'REGISTERED_AGENT'" "description" "Registered Agent"
  assert_cell "public.office_types" "code = 'SECRETARY'" "description" "Corporate Secretary"

  # Total office_types: 5 source rows (SANDBOX_ONLY not possible with enum)
  assert_row_count "public.office_types" "5"

  # Target-only row in corp_types should be preserved
  assert_cell "public.corp_types" "code = 'SC'" "description" "Sandbox Corp"

  # Source-only corp_types rows intact
  assert_cell "public.corp_types" "code = 'C'" "description" "Corporation"

  # Data tables restored correctly
  assert_row_count "public.businesses" "5"
  assert_row_count "public.filings" "6"
}
