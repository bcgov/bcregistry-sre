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
            role_type => try(db.database_role_assignment[role_type], [])
          }
        }
      ]
    }
  }

  triggers = {
    instance_config = jsonencode(each.value)
    global_assignments = jsonencode(var.global_assignments)
    env_assignments = jsonencode(var.environment_assignments)
    users = jsonencode(local.all_users)
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      set -ex
      INSTANCE="${each.value.instance}"
      PROJECT_ID="${var.project_id}"
      FULL_INSTANCE_NAME="$PROJECT_ID:northamerica-northeast1:$INSTANCE"

      # Process global assignments (applies to all databases)
      %{ for role_type in ["readonly", "readwrite", "admin"] ~}
      %{ for user in try(var.global_assignments[role_type], []) ~}
      %{ for db in each.value.databases ~}
      echo "Processing GLOBAL ${role_type} role for ${user} on ${db.db_name}"
      PAYLOAD=$(jq -n \
        --arg instance "$FULL_INSTANCE_NAME" \
        --arg role "${role_type}" \
        --arg db "${db.db_name}" \
        --arg user "${user}" \
        '{
          instance_name: $instance,
          role: $role,
          database: $db,
          user: $user,
          scope: "global"
        }'
      )
      curl -X POST "${var.cloud_function_url}" \
        -H "Authorization: Bearer ${data.google_service_account_id_token.invoker.id_token}" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        --fail || echo "Continuing despite error..."
      %{ endfor ~}
      %{ endfor ~}
      %{ endfor ~}

      # Process environment assignments (applies to all databases)
      %{ for role_type in ["readonly", "readwrite", "admin"] ~}
      %{ for user in try(var.environment_assignments[role_type], []) ~}
      %{ for db in each.value.databases ~}
      echo "Processing ENVIRONMENT ${role_type} role for ${user} on ${db.db_name}"
      PAYLOAD=$(jq -n \
        --arg instance "$FULL_INSTANCE_NAME" \
        --arg role "${role_type}" \
        --arg db "${db.db_name}" \
        --arg user "${user}" \
        '{
          instance_name: $instance,
          role: $role,
          database: $db,
          user: $user,
          scope: "environment"
        }'
      )
      curl -X POST "${var.cloud_function_url}" \
        -H "Authorization: Bearer ${data.google_service_account_id_token.invoker.id_token}" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        --fail || echo "Continuing despite error..."
      %{ endfor ~}
      %{ endfor ~}
      %{ endfor ~}

      # Process database-specific assignments
      %{ for db in each.value.databases ~}
      %{ for role_type in ["readonly", "readwrite", "admin"] ~}
      %{ for user in try(db.assignments[role_type], []) ~}
      echo "Processing DATABASE ${role_type} role for ${user} on ${db.db_name}"
      PAYLOAD=$(jq -n \
        --arg instance "$FULL_INSTANCE_NAME" \
        --arg role "${role_type}" \
        --arg db "${db.db_name}" \
        --arg user "${user}" \
        '{
          instance_name: $instance,
          role: $role,
          database: $db,
          user: $user,
          scope: "database"
        }'
      )
      curl -X POST "${var.cloud_function_url}" \
        -H "Authorization: Bearer ${data.google_service_account_id_token.invoker.id_token}" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        --fail || echo "Continuing despite error..."
      %{ endfor ~}
      %{ endfor ~}
      %{ endfor ~}
    EOT
  }
}
