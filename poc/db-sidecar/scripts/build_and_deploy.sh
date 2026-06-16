#!/bin/bash
set -eo pipefail

# Configuration
PROJECT_ID=$(gcloud config get-value project)
REGION="northamerica-northeast1"

echo "Using GCP Project: ${PROJECT_ID}"
echo "Using Region: ${REGION}"

# 1. Build and push image using Cloud Build
echo "Building and containerizing application with Cloud Build..."
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/flask-app:latest" .

# 2. Resolve Connection Name and compile service.yaml
echo "Resolving database connection name..."
CONNECTION_NAME=$(gcloud sql instances list --filter="name:common*" --format="value(connectionName)" 2>/dev/null | head -n 1)

if [ -z "$CONNECTION_NAME" ]; then
    echo "ERROR: Could not find any Cloud SQL instance starting with 'common'"
    exit 1
fi

echo "Found Connection Name: ${CONNECTION_NAME}"

export PROJECT_ID
export CONNECTION_NAME

echo "Generating service.yaml from template..."
python3 -c "
import os
template = open('service.yaml.template').read()
replaced = template.replace('\${PROJECT_ID}', os.environ['PROJECT_ID']).replace('\${CONNECTION_NAME}', os.environ['CONNECTION_NAME'])
open('service.yaml', 'w').write(replaced)
"

# 3. Deploy service using Knative service yaml
echo "Deploying Cloud Run service with dual-container architecture..."
gcloud run services replace service.yaml --region="${REGION}"

echo "Deployment complete successfully!"
