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

locals {
  # Create a flattened list of all role assignments
  all_role_assignments = distinct(flatten([
    for instance in var.instances : [
      for db in try(instance.databases, []) : [
        for role_type in ["readonly", "readwrite", "admin"] : [
          for user in try(db.database_role_assignment[role_type], []) : {
            instance = instance.instance
            db_name  = db.db_name
            role     = role_type
            user     = user
            key      = "${instance.instance}-${db.db_name}-${role_type}-${user}"
          }
        ]
      ]
    ]
  ]))

  # Create a flattened list of global/env role assignments
  global_env_assignments = distinct(flatten([
    for instance in var.instances : [
      for db in try(instance.databases, []) : [
        for role_type in ["readonly", "readwrite", "admin"] : [
          for user in distinct(concat(
            try(var.global_assignments[role_type], []),
            try(var.environment_assignments[role_type], [])
          )) : {
            instance = instance.instance
            db_name  = db.db_name
            role     = role_type
            user     = user
            key      = "${instance.instance}-${db.db_name}-${role_type}-${user}"
          }
        ]
      ]
    ]
  ]))

  # Combine all assignments, giving priority to database-specific ones
  combined_assignments = merge(
    { for a in local.all_role_assignments : a.key => a },
    # Only add global/env assignments if they don't conflict with db-specific ones
    { for a in local.global_env_assignments : a.key => a
      if !contains([for ra in local.all_role_assignments : ra.key], a.key)
    }
  )
}

resource "null_resource" "db_role_assignments" {
  for_each = local.combined_assignments

  triggers = {
    assignment = jsonencode(each.value)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -ex
      INSTANCE="${each.value.instance}"
      PROJECT_ID="${var.project_id}"
      REGION="${var.region}"
      FULL_INSTANCE_NAME="$PROJECT_ID:$REGION:$INSTANCE"
      GCS_URI="gs://${var.bucket_name}"

      PAYLOAD=$(jq -n \
        --arg instance "$FULL_INSTANCE_NAME" \
        --arg role "${each.value.role}" \
        --arg db "${each.value.db_name}" \
        --arg user "${each.value.user}" \
        --arg gcs_uri "$GCS_URI" \
        '{
          instance_name: $instance,
          role: $role,
          database: $db,
          user: $user,
          gcs_uri: $gcs_uri
        }'
      )

      echo "Processing ${each.value.role} role for ${each.value.user} on ${each.value.db_name}"
      echo "Payload: $PAYLOAD"

      RESPONSE=$(curl -v -X POST "${var.cloud_function_url}" \
        -H "Authorization: Bearer ${data.google_service_account_id_token.invoker.id_token}" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" 2>&1)

      echo "$RESPONSE"

      if ! echo "$RESPONSE" | grep -qE '^{.*}$'; then
        echo "ERROR: Failed to assign role"
        exit 1
      fi
    EOT
  }
}
