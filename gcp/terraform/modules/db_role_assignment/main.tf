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

  # All database users including both database-specific and global/env assignments
  db_users = distinct(concat(
    local.global_env_users,
    flatten([
      for instance in var.instances : [
        for db in try(instance.databases, []) : [
          for role_type in ["readonly", "readwrite", "admin"] :
          try(db.database_role_assignment[role_type], [])
        ]
      ]
    ])
  ))

  # Detect role conflicts (database-specific assignments only)
  role_conflicts = {
    for conflict in flatten([
      for instance in var.instances : [
        for db in try(instance.databases, []) : [
          for user in distinct(concat(
            try(db.database_role_assignment.readonly, []),
            try(db.database_role_assignment.readwrite, []),
            try(db.database_role_assignment.admin, [])
          )) : {
            key = "${instance.instance}-${db.db_name}-${user}"
            msg = "User ${user} has multiple roles on ${db.db_name} (${instance.instance}) - Roles: ${join(", ", compact([
              for role in ["readonly", "readwrite", "admin"] :
              role if contains(try(db.database_role_assignment[role], []), user)
            ]))}"
          } if length(compact([
            for role in ["readonly", "readwrite", "admin"] :
            role if contains(try(db.database_role_assignment[role], []), user)
          ])) > 1
        ]
      ]
    ]) : conflict.key => conflict.msg
  }

  # Combined role assignments (database-specific + global/env)
role_assignments = merge(
  # Database-specific assignments
  {
    for assignment in flatten([
      for instance in var.instances : [
        for db in try(instance.databases, []) : [
          for role_type in ["readonly", "readwrite", "admin"] : [
            for user in try(db.database_role_assignment[role_type], []) : {
              key      = "db-${instance.instance}-${db.db_name}-${role_type}-${user}"
              instance = instance.instance
              db_name  = db.db_name
              role     = role_type
              user     = user
            }
          ]
        ]
      ]
    ]) : assignment.key => assignment
  },
  # Global/env assignments applied to all databases
  {
    for assignment in flatten([
      for instance in var.instances : [
        for db in try(instance.databases, []) : [
          for role_type in ["readonly", "readwrite", "admin"] : [
            for user in local.global_env_users : {
              key      = "globalenv-${instance.instance}-${db.db_name}-${role_type}-${user}"
              instance = instance.instance
              db_name  = db.db_name
              role     = role_type
              user     = user
            } if contains(
              concat(
                try(var.global_assignments[role_type], []),
                try(var.environment_assignments[role_type], [])
              ),
              user
            )
          ]
        ]
      ]
    ]) : assignment.key => assignment
  }
)

  # Unique instance-user combinations
  instance_user_combinations = {
    for combo in distinct([
      for assignment in local.role_assignments : {
        instance = assignment.instance
        user     = assignment.user
      }
    ]) : "${combo.instance}-${combo.user}" => combo
  }
}

# Validate no role conflicts exist
resource "terraform_data" "validate_role_assignments" {
  input = {
    conflicts = local.role_conflicts
  }

  lifecycle {
    precondition {
      condition     = length(local.role_conflicts) == 0
      error_message = <<-EOT
        Database role conflicts detected:
        ${join("\n", [for msg in values(local.role_conflicts) : "  - ${msg}"])}

        Users cannot have multiple roles on the same database.
        Please fix these role assignments before applying.
      EOT
    }
  }
}

data "google_service_account_id_token" "invoker" {
  target_audience = var.cloud_function_url
  target_service_account = var.service_account_email
}

# Track instance-user combinations
resource "null_resource" "user_tracker" {
  for_each = local.instance_user_combinations

  depends_on = [terraform_data.validate_role_assignments]

  triggers = {
    user     = each.value.user
    instance = each.value.instance
    # Include all role assignments for this user
    roles = sha256(jsonencode([
      for assignment in local.role_assignments :
      assignment if assignment.instance == each.value.instance && assignment.user == each.value.user
    ]))
  }
}

resource "google_sql_user" "iam_account_users" {
  for_each = null_resource.user_tracker

  project  = var.project_id
  instance = each.value.triggers.instance

  name = (
    contains(keys(var.all_service_account_emails), each.value.triggers.user) ?
    trimsuffix(var.all_service_account_emails[each.value.triggers.user], ".gserviceaccount.com") :
    each.value.triggers.user
  )

  type = (
    contains(keys(var.all_service_account_emails), each.value.triggers.user) ?
    "CLOUD_IAM_SERVICE_ACCOUNT" :
    "CLOUD_IAM_USER"
  )

  lifecycle {
    replace_triggered_by = [null_resource.user_tracker[each.key].id]
  }
}

# Apply all role assignments
resource "null_resource" "db_role_assignments" {
  for_each = local.role_assignments

  depends_on = [google_sql_user.iam_account_users]

  triggers = {
    assignment = sha256(jsonencode(each.value))
    user_state = null_resource.user_tracker["${each.value.instance}-${each.value.user}"].id
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
      USER_EMAIL="${
        contains(keys(var.all_service_account_emails), each.value.user) ?
        trimsuffix(var.all_service_account_emails[each.value.user], ".gserviceaccount.com") :
        each.value.user
      }"
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
