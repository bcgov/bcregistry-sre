#!/bin/bash

REGION="northamerica-northeast1"

declare -a projects=("mvnjri")
declare -a environments=("prod")
DB_USER="pay"
DB_NAME="fin_warehouse"
SECRET_ID="DATA_WAREHOUSE_PAY_PASSWORD"
DB_INSTANCE_CONNECTION_NAME="mvnjri-prod:northamerica-northeast1:fin-warehouse-prod"

for ev in "${environments[@]}"
  do
      for ns in "${projects[@]}"
        do
          echo "project: $ns-$ev"
          PROJECT_ID=$ns-$ev

          if [[ ! -z `gcloud projects describe ${PROJECT_ID} --verbosity=none` ]]; then

            gcloud config set project $PROJECT_ID

            PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="get(projectNumber)")

            gcloud pubsub topics create pam-revoke-topic

            gcloud pubsub topics add-iam-policy-binding pam-revoke-topic \
            --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
            --role="roles/pubsub.publisher"

            gcloud secrets add-iam-policy-binding DATA_WAREHOUSE_SA_TOKEN \
            --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
            --role="roles/secretmanager.secretAccessor"

            gcloud projects add-iam-policy-binding "$PROJECT_ID" \
              --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
              --role="roles/cloudsql.admin"

            gcloud projects add-iam-policy-binding "$PROJECT_ID" \
              --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
              --role="roles/iam.serviceAccountAdmin"


            gcloud functions deploy pam-grant-revoke \
              --runtime python312 \
              --trigger-topic pam-revoke-topic \
              --entry-point pam_event_handler \
              --source cloud-functions/pam-grant-revoke \
              --set-env-vars DB_USER=${DB_USER},DB_NAME=${DB_NAME},DB_INSTANCE_CONNECTION_NAME=${DB_INSTANCE_CONNECTION_NAME},PROJECT_NUMBER=${PROJECT_NUMBER},SECRET_ID=${SECRET_ID} \
              --region  $REGION \
              --retry

            gcloud functions deploy pam-request-grant-create \
            --runtime python312 \
            --trigger-http \
            --entry-point create_pam_grant_request \
            --source cloud-functions/pam-request-grant-create \
            --set-env-vars DB_USER=${DB_USER},DB_NAME=${DB_NAME},DB_INSTANCE_CONNECTION_NAME=${DB_INSTANCE_CONNECTION_NAME},PROJECT_NUMBER=${PROJECT_NUMBER},PROJECT_ID=${PROJECT_ID},SECRET_ID=${SECRET_ID} \
            --region $REGION

          fi
      done
  done
