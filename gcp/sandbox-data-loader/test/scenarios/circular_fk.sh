#!/usr/bin/env bash
# =============================================================================
# test/scenarios/circular_fk.sh — Circular FK tables_only with FK_DEPTH=-1
# =============================================================================
#
# Scenario: Re-seed businesses table (which has circular FKs with filings)
#           without recreating the schema.
#
# Expected after pipeline:
#   - 5 businesses, 6 filings restored
#   - All 11 FK constraints exist and validate successfully
#   - No FK violations during data restore
# =============================================================================

export SCENARIO_MODE="tables_only"
export SCENARIO_TABLE_LIST="businesses"
export SCENARIO_FK_DEPTH="-1"
export SEED_FROM_TARGET_TABLES=
export SEED_CONFLICT_MODE=overwrite

setup() {
  # Nothing extra needed — schema_only already creates the schema with data
  # Verify source has data
  local src_count
  src_count=$(source_psql --tuples-only --no-align \
    -c "SELECT count(*) FROM public.businesses;")
  if [[ "$src_count" != "5" ]]; then
    echo "SETUP FAILED: source businesses count is ${src_count}, expected 5" >&2
    return 1
  fi
}

verify() {
  # Data restored correctly
  assert_row_count "public.businesses" "5"
  assert_row_count "public.filings" "6"

  # Circular FK data is valid (no constraint violation)
  assert_cell "public.businesses" "id = 1" "identifier" "BC0001000"
  assert_cell "public.filings" "id = 1" "business_id" "1"

  # All FK constraints exist
  local fk_count
  fk_count=$(target_psql --tuples-only --no-align \
    -c "SELECT count(*) FROM pg_constraint WHERE contype = 'f' AND connamespace = 'public'::regnamespace;")
  assert_eq "FK constraint count" "11" "$fk_count"

  # Validate all FK constraints (proves data integrity)
  target_psql -c "
    DO \$\$
    DECLARE r RECORD;
    BEGIN
      FOR r IN
        SELECT conname, conrelid::regclass::text AS tbl
        FROM pg_constraint
        WHERE contype = 'f' AND NOT convalidated AND connamespace = 'public'::regnamespace
      LOOP
        EXECUTE format('ALTER TABLE %I VALIDATE CONSTRAINT %I', r.tbl, r.conname);
      END LOOP;
    END
    \$\$;
  " >/dev/null 2>&1

  # After validation, all should be validated
  local unvalidated
  unvalidated=$(target_psql --tuples-only --no-align \
    -c "SELECT count(*) FROM pg_constraint WHERE contype = 'f' AND NOT convalidated AND connamespace = 'public'::regnamespace;")
  assert_eq "unvalidated FK constraints after VALIDATE" "0" "$unvalidated"
}
