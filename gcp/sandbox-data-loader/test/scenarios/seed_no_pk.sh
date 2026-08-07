#!/usr/bin/env bash
# =============================================================================
# test/scenarios/seed_no_pk.sh — No-PK table fallback to DO NOTHING
# =============================================================================
#
# Scenario: addresses table has no primary key.
#           overwrite mode should fall back to DO NOTHING for this table.
#
# Setup:
#   - Insert a row into target's addresses table
#
# Expected after pipeline:
#   - addresses row is preserved (INSERT ... ON CONFLICT DO NOTHING, no PK = no conflict = always inserts)
#   - Backup file contains "ON CONFLICT DO NOTHING" (not "DO UPDATE SET")
# =============================================================================

export SCENARIO_MODE="tables_only"
export SCENARIO_TABLE_LIST="businesses,addresses"
export SCENARIO_FK_DEPTH="-1"
export SEED_FROM_TARGET_TABLES="addresses"
export SEED_CONFLICT_MODE="overwrite"

setup() {
  target_psql -c "
    INSERT INTO public.addresses (id, business_id, street, city)
    VALUES (9999, 1, '123 Sandbox St', 'Testville');
  " >/dev/null

  local count
  count=$(target_psql --tuples-only --no-align \
    -c "SELECT count(*) FROM public.addresses WHERE id = 9999;")
  if [[ "$count" != "1" ]]; then
    echo "SETUP FAILED: addresses row not inserted" >&2
    return 1
  fi
}

verify() {
  # The backup file should use DO NOTHING (no PK found)
  assert_file_contains "/tmp/loader/seed_target_upsert.sql" "ON CONFLICT DO NOTHING" \
    "backup file uses ON CONFLICT DO NOTHING (no PK)"

  # No unique constraint on addresses → DO NOTHING doesn't prevent duplicates
  # Source has 3 rows, backup captured 4 (3 source + 1 custom), all re-insert
  # Total: 3 + 4 = 7
  assert_cell "public.addresses" "id = 9999" "street" "123 Sandbox St"
  assert_cell "public.addresses" "id = 9999" "city" "Testville"
  assert_row_count "public.addresses" "7"

  # Data tables restored correctly
  assert_row_count "public.businesses" "5"
  assert_row_count "public.filings" "6"
}
