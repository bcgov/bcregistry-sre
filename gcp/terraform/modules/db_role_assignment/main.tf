locals {
  # IAM Users Management
  global_env_users = distinct(concat(
    try(var.global_assignments.readonly, []),
    try(var.global_assignments.readwrite, []),
    try(var.global_assignments.admin, []),
    try(var.environment_assignments.readonly, []),
    try(var.environment_assignments.readwrite, []),
    try(var.environment_assignments.admin, [])
  ))

  db_users = distinct(flatten([
    for instance in var.instances : [
      for db in try(instance.databases, []) : [
        for role_type in ["readonly", "readwrite", "admin"] :
          try(db.database_role_assignment[role_type], [])
      ]
    ]
  ]))

  all_users = distinct(concat(local.global_env_users, local.db_users))

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

  # Role Assignment Processing with Database-Specific Priority
  role_assignments = {
    for assignment in flatten([
      for instance in var.instances : [
        for db in try(instance.databases, []) : [
          for role_type in ["readonly", "readwrite", "admin"] : [
            for user in distinct(concat(
              try(db.database_role_assignment[role_type], []),
              # Only include global/env users not specified at db level
              [for u in distinct(concat(
                try(var.global_assignments[role_type], []),
                try(var.environment_assignments[role_type], [])
              )) : u if !contains(try(db.database_role_assignment[role_type], []), u)]
            )) : {
              key      = "${instance.instance}-${db.db_name}-${role_type}-${user}"
              instance = instance.instance
              db_name  = db.db_name
              role     = role_type
              user     = user
            }
          ]
        ]
      ]
    ]) : assignment.key => assignment
  }
}

# IAM Users Creation
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

# Role Assignments
resource "null_resource" "db_role_assignments" {
  for_each = local.role_assignments

  depends_on = [google_sql_user.iam_account_users]

  triggers = {
    # Only trigger when the specific assignment changes
    assignment = sha256(jsonencode(each.value))
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -eo pipefail

      INSTANCE="${each.value.instance}"
      PROJECT_ID="${var.project_id}"
      REGION="${var.region}"
      FULL_INSTANCE_NAME="$PROJECT_ID:$REGION:$INSTANCE"
      GCS_URI="gs://${var.bucket_name}"
      USER_EMAIL="${each.value.user}"
      DB_NAME="${each.value.db_name}"
      ROLE_TYPE="${each.value.role}"

      PAYLOAD=$(jq -n \
        --arg instance "$FULL_INSTANCE_NAME" \
        --arg role "$ROLE_TYPE" \
        --arg db "$DB_NAME" \
        --arg user "$USER_EMAIL" \
        --arg gcs_uri "$GCS_URI" \
        '{
          instance_name: $instance,
          role: $role,
          database: $db,
          user: $user,
          gcs_uri: $gcs_uri
        }'
      )

      echo "Assigning $ROLE_TYPE role to $USER_EMAIL on $DB_NAME"
      RESPONSE=$(curl -sS -X POST "${var.cloud_function_url}" \
        -H "Authorization: Bearer ${data.google_service_account_id_token.invoker.id_token}" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD")

      echo "Response: $RESPONSE"
    EOT
  }
}
