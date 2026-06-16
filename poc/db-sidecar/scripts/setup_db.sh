#!/bin/bash
set -eo pipefail

# Configuration
PROJECT_ID=$(gcloud config get-value project)
INSTANCE_NAME=$(gcloud sql instances list --filter="name:common*" --format="value(name)" 2>/dev/null | head -n 1)

if [ -z "$INSTANCE_NAME" ]; then
    echo "ERROR: Could not find any Cloud SQL instance starting with 'common'"
    exit 1
fi

echo "Using GCP Project: ${PROJECT_ID}"
echo "Using SQL Instance: ${INSTANCE_NAME}"

# 1. Create the Cloud SQL IAM user (idempotent check)
echo "Checking if Cloud SQL IAM user already exists..."
if ! gcloud sql users list --instance="${INSTANCE_NAME}" --format="value(name)" 2>/dev/null | grep -q "^sa-cloud-run-db-user@${PROJECT_ID}.iam$"; then
    echo "Creating Cloud SQL IAM user in database..."
    gcloud sql users create "sa-cloud-run-db-user@${PROJECT_ID}.iam" \
        --instance="${INSTANCE_NAME}" \
        --type=CLOUD_IAM_SERVICE_ACCOUNT
else
    echo "Cloud SQL IAM user already exists in instance ${INSTANCE_NAME}."
fi

# 2. Compile setup_db.sql from template
export PROJECT_ID
echo "Generating scripts/setup_db.sql from template..."
python3 -c "
import os
template = open('scripts/setup_db.sql.template').read()
replaced = template.replace('\${PROJECT_ID}', os.environ['PROJECT_ID'])
open('scripts/setup_db.sql', 'w').write(replaced)
"

echo "Success! scripts/setup_db.sql generated."
echo "Connect to your Postgres database and run the SQL commands in scripts/setup_db.sql to grant permissions."
