#!/bin/bash
set -eo pipefail

# Configuration
PROJECT_ID=$(gcloud config get-value project)
SA_NAME="sa-cloud-run-db-user"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Using GCP Project: ${PROJECT_ID}"
echo "Service Account Email: ${SA_EMAIL}"

# 1. Check if Service Account exists, if not create it
if ! gcloud iam service-accounts describe "${SA_EMAIL}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    echo "Creating Service Account: ${SA_NAME}..."
    gcloud iam service-accounts create "${SA_NAME}" \
        --description="Service account for Cloud Run fast database sidecar connection" \
        --display-name="Cloud Run DB User" \
        --project="${PROJECT_ID}"
else
    echo "Service Account ${SA_EMAIL} already exists."
fi

# 2. Grant roles/cloudsql.client role to the service account
echo "Granting Cloud SQL Client role to service account..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/cloudsql.client" \
    --condition=None >/dev/null

# 3. Grant roles/cloudsql.instanceUser role to the service account
echo "Granting Cloud SQL Instance User role to service account..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/cloudsql.instanceUser" \
    --condition=None >/dev/null

echo "IAM Setup complete successfully!"
