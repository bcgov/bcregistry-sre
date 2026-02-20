#!/usr/bin/env bash

# Minimal script to redeploy pam-grant-revoke and pam-request-grant-create functions for all projects

REGION="northamerica-northeast1"
APIGEE_SA="apigee-prod-sa@okagqp-prod.iam.gserviceaccount.com"
declare -a projects=("c4hnrd" "gtksf3" "yfjq17" "a083gt" "keee67" "eogruh" "k973yf")

declare -a environments=("prod")

# Define associative arrays as in your main script
# (Copy the DB_USERS, DB_NAMES, DB_INSTANCE_CONNECTION_NAMES, DB_PASSWORD_SECRET_IDS definitions from your main script)
declare -A DB_USERS
declare -A DB_NAMES
declare -A DB_INSTANCE_CONNECTION_NAMES
declare -A DB_PASSWORD_SECRET_IDS

# DB_USERS["mvnjri-prod"]="pay"
# DB_NAMES["mvnjri-prod"]="fin_warehouse"
# DB_INSTANCE_CONNECTION_NAMES["mvnjri-prod"]="mvnjri-prod:northamerica-northeast1:fin-warehouse-prod"
# DB_PASSWORD_SECRET_IDS["mvnjri-prod"]="DATA_WAREHOUSE_PAY_PASSWORD"

DB_USERS["c4hnrd-prod"]="notifyuser,user4ca"
DB_NAMES["c4hnrd-prod"]="notify,docs"
DB_INSTANCE_CONNECTION_NAMES["c4hnrd-prod"]="c4hnrd-prod:northamerica-northeast1:notify-db-prod,c4hnrd-prod:northamerica-northeast1:common-db-prod"
DB_PASSWORD_SECRET_IDS["c4hnrd-prod"]="NOTIFY_USER_PASSWORD,USER4CA_PASSWORD"

DB_USERS["gtksf3-prod"]="postgres"
DB_NAMES["gtksf3-prod"]="auth-db"
DB_INSTANCE_CONNECTION_NAMES["gtksf3-prod"]="gtksf3-prod:northamerica-northeast1:auth-db-prod"
DB_PASSWORD_SECRET_IDS["gtksf3-prod"]="AUTH_USER_PASSWORD"

DB_USERS["yfjq17-prod"]="prodUser"
DB_NAMES["yfjq17-prod"]="bor"
DB_INSTANCE_CONNECTION_NAMES["yfjq17-prod"]="yfjq17-prod:northamerica-northeast1:bor-db-prod"
DB_PASSWORD_SECRET_IDS["yfjq17-prod"]="BOR_USER_PASSWORD"

DB_USERS["a083gt-prod"]="business-api"
DB_NAMES["a083gt-prod"]="business"
DB_INSTANCE_CONNECTION_NAMES["a083gt-prod"]="a083gt-prod:northamerica-northeast1:businesses-db-prod"
DB_PASSWORD_SECRET_IDS["a083gt-prod"]="BUSINESS_USER_PASSWORD"

DB_USERS["eogruh-prod"]="bni-hub,vans-prod"
DB_NAMES["eogruh-prod"]="bni-hub,vans-db-prod"
DB_INSTANCE_CONNECTION_NAMES["keee67-prod"]="keee67-prod:northamerica-northeast1:bn-hub-prod,keee67-prod:northamerica-northeast1:bn-hub-prod"
DB_PASSWORD_SECRET_IDS["keee67-prod"]="BNI_USER_PASSWORD,VANS_USER_PASSWORD"

DB_USERS["eogruh-prod"]="user4ca"
DB_NAMES["eogruh-prod"]="ppr"
DB_INSTANCE_CONNECTION_NAMES["eogruh-prod"]="eogruh-prod:northamerica-northeast1:ppr-prod"
DB_PASSWORD_SECRET_IDS["eogruh-prod"]="PPR_USER_PASSWORD"

DB_USERS["k973yf-prod"]="search_service"
DB_NAMES["k973yf-prod"]="search"
DB_INSTANCE_CONNECTION_NAMES["k973yf-prod"]="k973yf-prod:northamerica-northeast1:search-db-prod"
DB_PASSWORD_SECRET_IDS["k973yf-prod"]="SEARCH_USER_PASSWORD"

for ev in "${environments[@]}"; do
  for ns in "${projects[@]}"; do

    PROJECT_ID="$ns-$ev"
    # Explicitly set the active project for gcloud
    gcloud config set project "$PROJECT_ID"
    PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="get(projectNumber)")

    IFS=',' read -r -a DB_USER_ARRAY <<< ${DB_USERS[$PROJECT_ID]}
    IFS=',' read -r -a DB_NAME_ARRAY <<< ${DB_NAMES[$PROJECT_ID]}
    IFS=',' read -r -a DB_INSTANCE_ARRAY <<< ${DB_INSTANCE_CONNECTION_NAMES[$PROJECT_ID]}
    IFS=',' read -r -a DB_PASSWORD_ID_ARRAY <<< ${DB_PASSWORD_SECRET_IDS[$PROJECT_ID]}

    for ((i = 0; i < ${#DB_USER_ARRAY[@]}; i++)); do
      DB_USER="${DB_USER_ARRAY[i]}"
      DB_NAME="${DB_NAME_ARRAY[i]}"
      DB_INSTANCE_CONNECTION_NAME="${DB_INSTANCE_ARRAY[i]}"
      DB_PASSWORD_SECRET_ID="${DB_PASSWORD_ID_ARRAY[i]}"
      FUNCTION_SUFFIX="${DB_NAME//_/-}"

      # pam-grant-revoke

      gcloud functions deploy "pam-grant-revoke-${FUNCTION_SUFFIX}" \
        --runtime python312 \
        --trigger-topic "pam-revoke-topic-${FUNCTION_SUFFIX}" \
        --entry-point pam_event_handler \
        --source cloud-functions/pam-grant-revoke \
        --set-env-vars DB_INSTANCE_CONNECTION_NAME=${DB_INSTANCE_CONNECTION_NAME},PROJECT_NUMBER=${PROJECT_NUMBER} \
        --region $REGION \
        --service-account "sa-pam-function@${PROJECT_ID}.iam.gserviceaccount.com" \
        --retry \
        --project=${PROJECT_ID}

      # pam-request-grant-create

      gcloud functions deploy "pam-request-grant-create-${FUNCTION_SUFFIX}" \
        --runtime python312 \
        --trigger-http \
        --entry-point create_pam_grant_request \
        --source cloud-functions/pam-request-grant-create \
        --set-env-vars DB_USER=${DB_USER},DB_NAME=${DB_NAME},DB_INSTANCE_CONNECTION_NAME=${DB_INSTANCE_CONNECTION_NAME},PROJECT_NUMBER=${PROJECT_NUMBER},PROJECT_ID=${PROJECT_ID},SECRET_ID=${DB_PASSWORD_SECRET_ID},PUBSUB_TOPIC="pam-revoke-topic-${FUNCTION_SUFFIX}" \
        --region $REGION \
        --service-account "sa-pam-function@${PROJECT_ID}.iam.gserviceaccount.com" \
        --no-allow-unauthenticated \
        --project=${PROJECT_ID}

      gcloud functions add-invoker-policy-binding "pam-request-grant-create-${FUNCTION_SUFFIX}" --member="serviceAccount:${APIGEE_SA}" --region=$REGION --project=${PROJECT_ID}
    done
  done
done
