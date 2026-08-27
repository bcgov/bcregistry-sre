#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <project_id>"
  echo "Example: $0 my-other-product-project"
  exit 1
fi

PROJECT_ID=$1
EMAILS=("patrick.wei@gov.bc.ca" "andriy.bolyachevets@gov.bc.ca")
CHANNELS_JSON_ARRAY=()

echo "Setting up notifications in project: $PROJECT_ID"

# 1. Create Notification Channels
for EMAIL in "${EMAILS[@]}"; do
  EXISTING_CHANNEL=$(gcloud monitoring channels list \
    --project="$PROJECT_ID" \
    --filter="type=\"email\" AND labels.email_address=\"$EMAIL\"" \
    --format="value(name)" | head -n 1)

  if [ -z "$EXISTING_CHANNEL" ]; then
    echo "Creating notification channel for $EMAIL..."
    CHANNEL_NAME=$(gcloud monitoring channels create \
      --project="$PROJECT_ID" \
      --display-name="Email to $EMAIL" \
      --type=email \
      --channel-labels=email_address="$EMAIL" \
      --format="value(name)")
    CHANNELS_JSON_ARRAY+=("\"$CHANNEL_NAME\"")
  else
    echo "Notification channel for $EMAIL already exists: $EXISTING_CHANNEL"
    CHANNELS_JSON_ARRAY+=("\"$EXISTING_CHANNEL\"")
  fi
done

CHANNELS_JSON=$(IFS=,; echo "${CHANNELS_JSON_ARRAY[*]}")

# 2. Define Metrics (Using standard arrays for macOS bash 3.2 compatibility)
METRIC_NAMES=(
  "audit_config_change_monitor"
  "bucket_iam_monitor"
  "custom_roles_change_monitor"
  "owner_role_iam_change_monitor"
  "sql_instances_change_monitor"
)

METRIC_FILTERS=(
  'protoPayload.methodName="SetIamPolicy" AND protoPayload.serviceData.policyDelta.auditConfigDeltas:*'
  'resource.type=gcs_bucket AND protoPayload.methodName="storage.setIamPermissions"'
  'resource.type="iam_role" AND (protoPayload.methodName="google.iam.admin.v1.CreateRole" OR protoPayload.methodName="google.iam.admin.v1.DeleteRole" OR protoPayload.methodName="google.iam.admin.v1.UpdateRole")'
  '(protoPayload.serviceName="cloudresourcemanager.googleapis.com") AND (ProjectOwnership OR projectOwnerInvitee) OR (protoPayload.serviceData.policyDelta.bindingDeltas.action="REMOVE" AND protoPayload.serviceData.policyDelta.bindingDeltas.role="roles/owner") OR (protoPayload.serviceData.policyDelta.bindingDeltas.action="ADD" AND protoPayload.serviceData.policyDelta.bindingDeltas.role="roles/owner")'
  'protoPayload.methodName="cloudsql.instances.update" OR protoPayload.methodName="cloudsql.instances.create" OR protoPayload.methodName="cloudsql.instances.delete"'
)

METRIC_DESCS=(
  "Cloud Audit Logging produces admin activity and data access logs that enable security analysis, resource change tracking, and compliance auditing. By monitoring Audit Configuration changes, you ensure that all activities in your project can be audited at any time."
  "By monitoring changes to Cloud Storage bucket permissions, can help you identify over-privileged users or suspicious activity at early stages."
  "Cloud IAM provides predefined and custom roles that grant access to specific GCP resources. By monitoring role creation, deletion, and update activities, you can identify over-privileged roles at early stages."
  "The Cloud IAM Owner role has the highest level of privilege on a project. To secure your resources, set up alerts to get notified when new owners are added or removed."
  "Misconfiguration of SQL instance options can cause security risks, like adverse impact on business continuity with the Enable auto backups and high availability options, or increased exposure to untrusted networks with the Authorized networks options. By monitoring changes to SQL instance configuration, you can help reduce the time to detect and correct misconfigurations."
)

# 3. Create Metrics and Alerts
for i in "${!METRIC_NAMES[@]}"; do
  METRIC="${METRIC_NAMES[$i]}"
  FILTER="${METRIC_FILTERS[$i]}"
  DESC="${METRIC_DESCS[$i]}"

  echo "----------------------------------------"
  echo "Processing $METRIC..."
  
  # Check if metric exists
  if gcloud logging metrics describe "$METRIC" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "Metric $METRIC already exists. Skipping creation."
  else
    echo "Creating metric $METRIC..."
    gcloud logging metrics create "$METRIC" \
      --project="$PROJECT_ID" \
      --description="$DESC" \
      --log-filter="$FILTER"
  fi

  # Escape double quotes for JSON formatting
  ESCAPED_FILTER=$(echo "$FILTER" | sed 's/"/\\"/g')
  
  POLICY_FILE="/tmp/policy_${METRIC}.json"
  cat <<EOF > "$POLICY_FILE"
{
  "displayName": "Alert for $METRIC",
  "combiner": "OR",
  "conditions": [
    {
      "displayName": "Log match condition",
      "conditionMatchedLog": {
        "filter": "$ESCAPED_FILTER"
      }
    }
  ],
  "notificationChannels": [
    $CHANNELS_JSON
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "300s"
    }
  }
}
EOF

  echo "Creating alert policy for $METRIC..."
  gcloud monitoring policies create --policy-from-file="$POLICY_FILE" --project="$PROJECT_ID" || true
done

echo "========================================"
echo "Successfully created metrics and alerts for project $PROJECT_ID!"
