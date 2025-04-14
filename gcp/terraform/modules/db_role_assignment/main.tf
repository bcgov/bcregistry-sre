locals {
  # Collect all users from global and environment assignments
  global_env_users = distinct(concat(
    try(var.global_assignments.readonly, []),
    try(var.global_assignments.readwrite, []),
    try(var.global_assignments.admin, []),
    try(var.environment_assignments.readonly, []),
    try(var.environment_assignments.readwrite, []),
    try(var.environment_assignments.admin, [])
  ))

  # Collect all users from database-level assignments
  db_users = distinct(flatten([
    for instance in var.instances : [
      for db in try(instance.databases, []) : [
        for role_type in ["readonly", "readwrite", "admin"] :
          try(db.database_role_assignment[role_type], [])
      ]
    ]
  ]))

  # Combine all unique users that need IAM access
  all_users = distinct(concat(local.global_env_users, local.db_users))

  # Create a map of which users need to be created for which instances
  users_per_instance = {
    for instance in var.instances : instance.instance => distinct(concat(
      local.global_env_users,
      flatten([
        for db in try(instance.databases, []) : [
          for role_type in ["readonly", "readwrite", "admin"] :
            try(db.database_role_assignment[role_type], [])
        ]
      ])
    ))
  }
}

# Create IAM users for each instance they need access to
resource "google_sql_user" "iam_account_users" {
  for_each = {
    for user_instance in flatten([
      for instance_name, users in local.users_per_instance : [
        for user in users : {
          instance = instance_name
          user     = user
        }
      ]
    ]) : "${user_instance.instance}-${user_instance.user}" => user_instance
  }

  project  = var.project_id
  name     = each.value.user
  instance = each.value.instance
  type     = "CLOUD_IAM_USER"

}

data "google_service_account_id_token" "invoker" {
  target_audience = var.cloud_function_url
  target_service_account = var.service_account_email
}

resource "null_resource" "db_role_assignments" {
  for_each = {
    for instance in var.instances :
    instance.instance => {
      instance = instance.instance
      databases = [
        for db in try(instance.databases, []) : {
          db_name = db.db_name
          assignments = {
            for role_type in ["readonly", "readwrite", "admin"] :
            role_type => {
              # Combine global, environment, and db-specific assignments, then deduplicate
              users = distinct(concat(
                try(var.global_assignments[role_type], []),
                try(var.environment_assignments[role_type], []),
                try(db.database_role_assignment[role_type], [])
              ))
            }
          }
        }
      ]
    }
  }

  triggers = {
    # test trigger
    # run_at = timestamp()
    instance_config = jsonencode(each.value)
    users = jsonencode(local.all_users)
  }

  provisioner "local-exec" {
    when    = create
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -ex
      INSTANCE="${each.value.instance}"
      PROJECT_ID="${var.project_id}"
      REGION="${var.region}"
      FULL_INSTANCE_NAME="$PROJECT_ID:$REGION:$INSTANCE"
      GCS_URI="gs://${var.bucket_name}"

      # Function to handle role assignment
      assign_role() {
        local instance=$1
        local role=$2
        local db=$3
        local user=$4

        echo "Processing $role role for $user on $db"

        PAYLOAD=$(jq -n \
          --arg instance "$instance" \
          --arg role "$role" \
          --arg db "$db" \
          --arg user "$user" \
          --arg gcs_uri "$GCS_URI" \
          '{
            instance_name: $instance,
            role: $role,
            database: $db,
            user: $user,
            gcs_uri: $gcs_uri
          }'
        )

        echo "Payload: $PAYLOAD"

        RESPONSE=$(curl -v -X POST "${var.cloud_function_url}" \
          -H "Authorization: Bearer ${data.google_service_account_id_token.invoker.id_token}" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" 2>&1)

        echo "$RESPONSE"

        BODY=$(echo "$RESPONSE" | grep -E '^{.*}$')
        echo "Success: $BODY"
        return 0
      }

      export -f assign_role

      FAILED=0
      {
        %{ for db in each.value.databases ~}
        %{ for role_type in ["readonly", "readwrite", "admin"] ~}
        %{ for user in db.assignments[role_type].users ~}
        if ! assign_role "$FULL_INSTANCE_NAME" "${role_type}" "${db.db_name}" "${user}"; then
          FAILED=$((FAILED + 1))
        fi
        %{ endfor ~}
        %{ endfor ~}
        %{ endfor ~}
      } | tee -a role_assignment.log

      if [ "$FAILED" -gt 0 ]; then
        echo "ERROR: Failed to assign $FAILED roles"
        exit 1
      fi
    EOT
  }
}
