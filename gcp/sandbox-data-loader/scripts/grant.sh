#!/usr/bin/env bash
# =============================================================================
# scripts/grant.sh — Transfer object ownership after restore
# =============================================================================
#
# pg_dump runs with --no-owner, so restored objects are owned by the IAM user
# (TARGET_DB_USER). This script reassigns them to DB_OWNER_ROLE.
#
# Everything else (role creation, memberships, schema permissions) is managed
# by Terraform.
#
# Reads from:
#   TARGET_DB, TARGET_DB_USER, TARGET_SCHEMA
#   DB_OWNER_ROLE
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/log.sh"

TARGET_PGHOST="${TARGET_PGHOST:-127.0.0.1}"
TARGET_PGPORT="${TARGET_PGPORT:-5434}"

# =============================================================================
# Transfer object ownership
# =============================================================================
main() {
  local owner_role="${DB_OWNER_ROLE:-}"
  if [[ -z "$owner_role" ]]; then
    log_warn "DB_OWNER_ROLE not set — skipping ownership transfer."
    exit 0
  fi

  log_info "Reassigning objects owned by ${TARGET_DB_USER} to ${owner_role}..."

  export PGPASSWORD="${DB_PASSWORD:-iam}"
  export PGUSER="${TARGET_DB_USER}"

  # Grant USAGE on public schema to DB_OWNER_ROLE for objects that exist
  # in public (e.g., pgcrypto extension functions from 'anon' CASCADE).
  # PostgreSQL requires the new owner to have USAGE on the schema before
  # ALTER ... OWNER TO will accept the transfer.
  # In Cloud SQL mode, escalate to cloudsqlsuperuser to make the grant
  # (granted to admin via one-time bootstrap; the IAM user is a member of admin).
  # In local mode, skip SET ROLE — the user already has sufficient privileges.
  if [[ "${USE_PROXY:-false}" == "true" ]]; then
    psql \
      -h "${TARGET_PGHOST}" \
      -p "${TARGET_PGPORT}" \
      -U "${TARGET_DB_USER}" \
      -d "${TARGET_DB}" \
      --set ON_ERROR_STOP=1 \
      -c "SET ROLE \"cloudsqlsuperuser\"; GRANT USAGE ON SCHEMA public TO \"${owner_role}\"; RESET ROLE;"
  else
    psql \
      -h "${TARGET_PGHOST}" \
      -p "${TARGET_PGPORT}" \
      -U "${TARGET_DB_USER}" \
      -d "${TARGET_DB}" \
      --set ON_ERROR_STOP=1 \
      -c "GRANT USAGE ON SCHEMA public TO \"${owner_role}\";"
  fi

  # Per-schema DO block replaces REASSIGN OWNED because the 'anon'
  # extension creates an event trigger (anon_trg_check_trusted_schemas)
  # that the IAM user owns, and event triggers require a superuser to
  # reassign (unavailable on Cloud SQL). REASSIGN OWNED is atomic — a
  # single failure rolls back all transfers. A PL/pgSQL DO block skips
  # event triggers entirely (they are database-level, not schema-scoped).

  # Generate and run ownership transfer SQL for all object types
  # sed placeholders: __SCHEMA__, __OWNER__
  cat > /tmp/loader/transfer_ownership.sql <<'SQLEOF'
DO $do$
DECLARE
  r record;
BEGIN
  -- Schema
  EXECUTE format('ALTER SCHEMA %I OWNER TO %I', '__SCHEMA__', '__OWNER__');

  -- Tables in target schema
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = '__SCHEMA__' LOOP
    EXECUTE format('ALTER TABLE %I.%I OWNER TO %I', '__SCHEMA__', r.tablename, '__OWNER__');
  END LOOP;

  -- Views
  FOR r IN SELECT viewname FROM pg_views WHERE schemaname = '__SCHEMA__' LOOP
    EXECUTE format('ALTER VIEW %I.%I OWNER TO %I', '__SCHEMA__', r.viewname, '__OWNER__');
  END LOOP;

  -- Sequences
  FOR r IN SELECT sequencename FROM pg_sequences WHERE schemaname = '__SCHEMA__' LOOP
    EXECUTE format('ALTER SEQUENCE %I.%I OWNER TO %I', '__SCHEMA__', r.sequencename, '__OWNER__');
  END LOOP;

  -- Functions and procedures in target schema owned by current user
  FOR r IN
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args,
           CASE WHEN p.prokind = 'p' THEN 'ALTER PROCEDURE' ELSE 'ALTER FUNCTION' END AS alter_type
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = '__SCHEMA__'
      AND p.prokind IN ('f', 'p')
      AND p.proowner = (SELECT oid FROM pg_roles WHERE rolname = current_user)
  LOOP
    IF length(r.args) > 0 THEN
      EXECUTE format('%s %I.%I(%s) OWNER TO %I', r.alter_type, '__SCHEMA__', r.proname, r.args, '__OWNER__');
    ELSE
      EXECUTE format('%s %I.%I() OWNER TO %I', r.alter_type, '__SCHEMA__', r.proname, '__OWNER__');
    END IF;
  END LOOP;

  -- Functions and procedures in public owned by current user
  FOR r IN
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args,
           CASE WHEN p.prokind = 'p' THEN 'ALTER PROCEDURE' ELSE 'ALTER FUNCTION' END AS alter_type
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind IN ('f', 'p')
      AND p.proowner = (SELECT oid FROM pg_roles WHERE rolname = current_user)
  LOOP
    IF length(r.args) > 0 THEN
      EXECUTE format('%s public.%I(%s) OWNER TO %I', r.alter_type, r.proname, r.args, '__OWNER__');
    ELSE
      EXECUTE format('%s public.%I() OWNER TO %I', r.alter_type, r.proname, '__OWNER__');
    END IF;
  END LOOP;
END;
$do$;
SQLEOF

  sed "s/__SCHEMA__/${TARGET_SCHEMA}/g; s/__OWNER__/${owner_role}/g" \
    /tmp/loader/transfer_ownership.sql > /tmp/loader/transfer_ownership.sql.tmp
  mv /tmp/loader/transfer_ownership.sql.tmp /tmp/loader/transfer_ownership.sql

  psql \
    -h "${TARGET_PGHOST}" \
    -p "${TARGET_PGPORT}" \
    -U "${TARGET_DB_USER}" \
    -d "${TARGET_DB}" \
    --set ON_ERROR_STOP=1 \
    -f /tmp/loader/transfer_ownership.sql

  unset PGPASSWORD PGUSER

  log_info "Ownership transfer complete."
}

main "$@"
