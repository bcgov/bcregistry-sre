---
description: "Generate production-grade GCP Cloud Run Job for database refresh - supports full/schema/table-level sync, data masking, synthetic data injection, and safe destructive operations for Cloud SQL PostgreSQL across projects"
name: "GCP Sandbox Database Loader"
argument-hint: "Generate infrastructure and scripts"
agent: "agent"
tools: [search, file, terminal]
---

# GCP Database Refresh System Generator

You are generating production-grade infrastructure + scripts for a GCP-based database refresh system.

## Goal

Build a Cloud Run Job (or equivalent GCP Job setup) that synchronizes a production Cloud SQL PostgreSQL database into a sandbox Cloud SQL PostgreSQL database across different GCP projects.

## System Capabilities

The system must support:
- **Full database refresh** (schema + data)
  - i.e. load entire production database into sandbox
- **Schema-only refresh**
  - i.e. load only the schema structure (tables, views, functions) without data
- **Table-level refresh** (selected tables)
  - i.e. load only specific tables from production into sandbox (schema only or schema + data)
- **Optional data masking** using PostgreSQL anon extension
- **Optional synthetic data injection** (from SQL files in GCS)
- **Safe handling of destructive operations** (drop/recreate DB or truncate tables, via GCP Cloud SQL backups)
- **Execution via Cloud Run Job** OR containerized script triggered by Cloud Scheduler / Cloud Build
- **Data movement via Cloud Storage** (pg_dump / pg_restore or gcloud sql import/export)
- **Cloud SQL Auth Proxy** for secure connectivity

## Constraints

- Production and sandbox are in **separate GCP projects**
- Must use **service accounts with least privilege**
- Must be **idempotent and retry-safe**
- Must include **logging and error handling**
- Must **avoid leaking prod credentials** into sandbox logs
- Must support **Postgres only**

## Authentication & Connectivity

### Application Default Credentials (ADC)

The system uses **Application Default Credentials** for all GCP service authentication:

**In Cloud Run Job (Production):**
- Service account attached to Cloud Run Job provides ADC automatically
- No explicit credential files or environment variables needed
- Cloud SQL Proxy, gcloud CLI, and GCS access all use ADC

**Local Development:**
```bash
# One-time setup: authenticate with your GCP account
gcloud auth application-default login

# Verify authentication
gcloud auth application-default print-access-token
```

### Cloud SQL Connectivity via Proxy

**Why Cloud SQL Proxy is Required:**
- `pg_dump` and `pg_restore` require direct PostgreSQL protocol connectivity
- Cloud SQL instances are not publicly accessible (security best practice)
- Cloud SQL Proxy provides secure tunnel using IAM authentication

**Proxy Authentication:**
```bash
# Proxy uses ADC automatically - no credentials needed
# --auto-iam-authn enables automatic IAM database authentication
cloud-sql-proxy <project>:<region>:<instance> --port 5432 --auto-iam-authn

# In Cloud Run: uses job's service account
# Locally: uses developer's gcloud credentials
```

**Multiple Proxy Pattern (source + target):**
```bash
# Source (production) - port 5432
cloud-sql-proxy prod-project:northamerica-northeast1:prod-instance \
  --port 5432 --auto-iam-authn &
SOURCE_PROXY_PID=$!

# Target (sandbox) - port 5433 (avoid conflict)
cloud-sql-proxy sandbox-project:northamerica-northeast1:sandbox-instance \
  --port 5433 --auto-iam-authn &
TARGET_PROXY_PID=$!

# Cleanup
kill $SOURCE_PROXY_PID $TARGET_PROXY_PID
```

### IAM Database Authentication

**Prerequisites:**
- IAM database users already exist in Cloud SQL (created separately by DBA/admin)
- Cloud SQL Proxy must be started with `--auto-iam-authn` flag

**Setup in Cloud SQL:**
```sql
-- Create IAM database users (assumes these are created by admin)
-- User name format: service-account-email@project-id.iam

**Usage in scripts:**
```bash
# No password needed - IAM authentication via Cloud SQL Proxy with --auto-iam-authn
export PGPASSWORD=""  # Empty password for IAM auth
export PGUSER="sa-db-reader@prod-project.iam"

pg_dump -h localhost -p 5432 -U "$PGUSER" -d prod_db \
  --no-owner --no-privileges --format=plain --file=dump.sql

unset PGPASSWORD
```

## Architecture Requirements

### 1. Containerized Job (Dockerfile)

Create a Docker container with:
- PostgreSQL client tools (pg_dump, pg_restore, psql) version 15+
- gcloud CLI (for Cloud SQL Proxy and GCS access)
- Cloud SQL Proxy v2 (latest stable)
- Python 3.12+ OR bash 5+ for orchestration
- Optional: PostgreSQL anon extension tools
- jq for config parsing

### 2. Orchestration Script

Entry-point script (bash or python) that orchestrates:
- Start Cloud SQL Proxy for source and target databases
- Validate environment variables and safety checks
- Dump schema/data using pg_dump
- Upload dump to GCS staging bucket
- Restore into sandbox DB (with connection termination, extension setup)
- Stop proxies and cleanup

### 3. Transformation Stage (Optional)

- Apply anon extension masking rules
- Apply SQL masking scripts (mask.sql from GCS)
- Apply synthetic data inserts (seed.sql or CSV import scripts)


### 4. Cleanup Logic

- Terminate active connections before restore
- Drop/recreate DB or truncate selected tables safely
- Handle extension dependencies (create before restore)

## Functional Modes

Must implement via CLI flags or environment variables:

- `MODE=full_refresh` - Complete database dump and restore
- `MODE=schema_only` - Schema structure only, no data
- `MODE=tables_only` - Specific tables (TABLE_LIST env var)
- `MASKING_ENABLED=true/false` - Apply data masking
- `SEED_DATA_ENABLED=true/false` - Inject synthetic data

## GCP Specifics

### Cloud SQL Proxy

**Connection Pattern:**
```bash
# Start proxy in background with IAM authentication enabled
cloud-sql-proxy <project>:<region>:<instance> --port <port> --auto-iam-authn &
PROXY_PID=$!

# Wait for ready
sleep 5

# Verify proxy is running
kill -0 $PROXY_PID || { echo "Proxy failed"; exit 1; }

# Cleanup on exit
trap "kill $PROXY_PID 2>/dev/null" EXIT
```

**Important flags:**
- `--auto-iam-authn` - Enables automatic IAM database authentication (required for IAM users)
- `--structured-logs` - JSON structured logging (recommended for production)
- `--port` - Local port to listen on

### Cloud Storage Staging

**Bucket Structure:**
```
gs://<project>-db-dumps/
  ├── dumps/              # Database dumps (timestamped)
  ├── scripts/            # Masking and seed scripts
  │   ├── mask.sql
  │   └── seeds/
  │       ├── 01_users.sql
  │       └── 02_orders.sql
  └── logs/               # Job execution logs
```

**GCS Operations:**
```bash
# Upload dump
gcloud storage cp /tmp/dump.sql gs://${GCS_BUCKET}/dumps/dump_${TIMESTAMP}.sql

# Download masking scripts
gcloud storage cp --recursive gs://${GCS_BUCKET}/scripts/ /tmp/scripts/

# List existing dumps (for idempotency check)
gcloud storage ls gs://${GCS_BUCKET}/dumps/
```

## PostgreSQL Specifics

### Extensions

**Extract from source database:**
```sql
SELECT 'CREATE EXTENSION IF NOT EXISTS "' || e.extname || '" SCHEMA ' || n.nspname || ';'
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
WHERE n.nspname = 'public';
```

**Recreate in target before restore:**
```bash
# Extract extensions to file
psql -h localhost -p 5432 -U "$SOURCE_USER" -d "$SOURCE_DB" \
  --tuples-only --no-align -c "SELECT ..." > extensions.sql

# Create in target (before data restore)
psql -h localhost -p 5433 -U "$TARGET_USER" -d "$TARGET_DB" -f extensions.sql
```

**Common dependencies:**
- `pgcrypto` (required by anon extension)
- `uuid-ossp` (UUID generation)

### Ownership & Privileges

**Why `--no-owner --no-privileges`:**
- Source and target databases may have different users
- Prod users shouldn't exist in sandbox
- Custom grants applied post-restore via grant.sh

**pg_dump command:**
```bash
pg_dump -h localhost -p 5432 -U "$SOURCE_USER" -d "$SOURCE_DB" \
  --no-owner \           # Don't restore object ownership
  --no-privileges \      # Don't restore grants
  --format=plain \       # Plain SQL (human-readable)
  --verbose \
  --file=dump.sql
```

### Session Configuration

**Use `session_replication_role = replica` during restore:**
- Bypasses triggers (faster restore)
- Bypasses foreign key checks (allows any order)
- Bypasses rules

**Restore pattern:**
```bash
{
  echo "SET session_replication_role = 'replica';"
  cat dump.sql
  echo "SET session_replication_role = 'origin';"
} | psql -h localhost -p 5433 -U "$TARGET_USER" -d "$TARGET_DB"
```

**Alternative: Filter out transaction control:**
```bash
# Remove BEGIN/COMMIT for better error handling
sed '/^\\[^.]/ d; /^BEGIN;/d; /^COMMIT;/d' dump.sql > filtered_dump.sql
psql ... -f filtered_dump.sql
```

### Connection Management

**Terminate active sessions before DROP DATABASE:**
```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'target_db'
  AND pid <> pg_backend_pid();
```

**Polling pattern (ensure all connections terminated):**
```bash
while psql -U "$ADMIN_USER" -h localhost -p 5433 -d postgres -tAc \
  "SELECT 1 FROM pg_stat_activity WHERE datname = '$TARGET_DB' AND pid <> pg_backend_pid()" | grep -q 1
do
  psql -U "$ADMIN_USER" -h localhost -p 5433 -d postgres -c \
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$TARGET_DB' AND pid <> pg_backend_pid();"
  sleep 1
done
```

## Masking Requirements

When `MASKING_ENABLED=true`:
1. Install/enable anon extension
2. Apply masking configuration from `masking.yaml`:
   - Per-table rules
   - Column-level transformations (hash, fake, null, partial)
3. Run `mask.sql` from GCS after restore OR during pipeline
4. Support masking strategies:
   - Hash (irreversible)
   - Faker functions (realistic fake data)
   - Null/redact (remove sensitive data)
   - Partial (mask@email.com → m***@email.com)

Example masking.yaml:
```yaml
tables:
  users:
    email: "anon.fake_email()"
    phone: "anon.partial(phone, 'XXX-XXX-', 4)"
    ssn: "NULL"
  transactions:
    card_number: "anon.hash(card_number)"
```

## Synthetic Data

When `SEED_DATA_ENABLED=true`:
1. Load SQL files from `gs://<project>-db-scripts/seeds/*.sql`
2. OR load CSV files with custom loaders
3. Execute AFTER masking (masking → seeding order)
4. Support idempotent inserts (ON CONFLICT DO NOTHING or DELETE first)

## Observability & Logging

Print structured logs with:
- **Step markers**: `[START] Dumping schema`, `[END] Restore complete`
- **Metrics**: DB size, table counts, row counts per table
- **Timing**: Duration per phase (dump: 2m 34s, restore: 5m 12s)
- **Error context**: Which step failed, error message, exit code

Log format example:
```
[2026-06-18 10:23:45] [INFO] Starting full_refresh mode
[2026-06-18 10:23:46] [INFO] Source DB: prod-project:northamerica-northeast1:prod-db
[2026-06-18 10:23:46] [INFO] Target DB: sandbox-project:northamerica-northeast1:sandbox-db
[2026-06-18 10:23:47] [START] Dumping schema and data
[2026-06-18 10:26:21] [END] Dump complete (2m 34s, 1.2 GB)
```

**Fail fast** on errors unless explicitly marked `NON_FATAL` in config.

## Security

- **No hardcoded credentials** - all via env vars, ADC, or IAM database users
- **Credential isolation**: Prod SA cannot write to sandbox, sandbox SA has limited prod read
- **Log sanitization**: Redact connection strings, passwords from logs
- **GCS bucket versioning**: Enable for audit trail of dumps
- **Empty PGPASSWORD for IAM auth**: `export PGPASSWORD=""` prevents password leaks
- **Cleanup sensitive data**: `unset PGPASSWORD` after database operations

## Required Deliverables

Generate the following files:

### 1. Dockerfile
- Base image: `google/cloud-sdk:alpine`
- Install: postgresql15-client, bash, python3, jq
- Download Cloud SQL Proxy v2 binary
- Copy orchestration and helper scripts
- Set entrypoint

### 2. Orchestration Script
- `entrypoint.sh` (bash) - Main orchestrator
- Parse and validate environment variables
- Start Cloud SQL Proxies (source + target)
- Call helper scripts in sequence
- Handle errors and cleanup (trap EXIT)

### 3. Helper Scripts
- `dump.sh` - Export from prod (pg_dump)
- `restore.sh` - Import to sandbox (psql, connection termination, extension setup)
- `mask.sh` - Apply anon extension + masking SQL
- `seed.sh` - Load synthetic data from GCS
- `grant.sh` - Create users and set permissions

### 4. Configuration Examples

**.env.example**:
```bash
# Execution Mode
MODE=full_refresh
TABLE_LIST=""

# Source Database (Production)
SOURCE_PROJECT=prod-project-id
SOURCE_REGION=northamerica-northeast1
SOURCE_INSTANCE=prod-cloudsql-instance
SOURCE_DB=production_database
SOURCE_SCHEMA=public

# Source Authentication (IAM preferred)
SOURCE_DB_USER=sa-db-reader@prod-project.iam
SOURCE_DB_PASSWORD=""  # Empty for IAM auth

# Target Database (Sandbox)
TARGET_PROJECT=sandbox-project-id
TARGET_REGION=northamerica-northeast1
TARGET_INSTANCE=sandbox-cloudsql-instance
TARGET_DB=sandbox_database
TARGET_SCHEMA=public

# Target Authentication (IAM preferred)
TARGET_DB_USER=sa-db-admin@sandbox-project.iam
TARGET_DB_PASSWORD=""

# Admin user for DDL operations
REPLICA_ADMIN=sa-db-admin@sandbox-project.iam

# GCS Configuration
GCS_BUCKET=my-project-db-dumps

# Optional Features
MASKING_ENABLED=false
SEED_DATA_ENABLED=false

# Operational Settings
BACKUP_BEFORE_RESTORE=true
SKIP_EXISTING_DUMP=false
FAIL_FAST=true
LOG_LEVEL=INFO

# Safety Overrides
ALLOW_PROD_TARGET=false
```

**masking.yaml.example** - Sample masking configuration

**grant.sql.example** - Sample permission setup

### 5. Documentation

**README.md** - Complete setup and usage guide:
- Prerequisites
- Local development setup
- Environment variable configuration
- Running the job
- Troubleshooting

## Design Principles

**Modularity**: Each step executable independently:
```bash
./scripts/dump.sh
./scripts/restore.sh
./scripts/mask.sh
./scripts/seed.sh
./scripts/grant.sh
```

**Safety**:
- Confirm target is sandbox (not prod)
- Backup existing sandbox data before overwrite
- Require explicit `ALLOW_PROD_TARGET=true` for prod-named instances
- Terminate connections before DROP DATABASE

**Idempotency**:
- Use `CREATE EXTENSION IF NOT EXISTS`
- Use `DROP DATABASE IF EXISTS` + `CREATE DATABASE`
- Check if dump exists in GCS

**Retry-safety**:
- Check if dump exists before dumping
- Support partial workflow execution
- Log progress markers

## Implementation Notes

**Language choice:**
- Use **bash** for orchestration
- Use **Python** only if YAML parsing needed

**Critical implementation details:**
- **Always terminate connections before DROP DATABASE** (polling loop pattern)
- **Always use `--no-owner --no-privileges` in pg_dump**
- **Always start Cloud SQL Proxy with `--auto-iam-authn` flag** (required for IAM auth)
- **Always start Cloud SQL Proxy in background with cleanup** (trap EXIT)
- **Always clear PGPASSWORD after use** (`unset PGPASSWORD`)
- **Always verify proxy started** (`kill -0 $PROXY_PID`)
- **Always use separate ports** (5432, 5433)

**Comments to include:**
- Why we terminate connections before restore
- Why we use `--no-owner --no-privileges`
- How Cloud SQL Auth Proxy works with IAM (`--auto-iam-authn` flag)
- Why `session_replication_role = replica` speeds up restore
- Security implications of each permission grant

Make the implementation production-grade, safe for destructive operations, and suitable for repeated automated sandbox refreshes.
