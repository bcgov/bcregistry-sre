#!/bin/bash

PROJECT_ID="c4hnrd-tools"
REGION="northamerica-northeast1"

gcloud config set project "$PROJECT_ID"

PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="get(projectNumber)")

gcloud functions deploy "db-roles-create" \
    --runtime python312 \
    --trigger-http \
    --entry-point execute_role_management \
    --source db-roles \
    --region $REGION \
    --service-account "sa-cloud-function-sql-manager@${PROJECT_ID}.iam.gserviceaccount.com" \
    --timeout=360s \
    --no-allow-unauthenticated

gcloud functions deploy "db-roles-assign" \
    --runtime python312 \
    --trigger-http \
    --entry-point grant_db_role \
    --source db-role-management \
    --region $REGION \
    --service-account "sa-cloud-function-sql-manager@${PROJECT_ID}.iam.gserviceaccount.com" \
    --timeout=360s \
    --no-allow-unauthenticated
