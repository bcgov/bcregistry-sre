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

  lifecycle {
    prevent_destroy = true
  }
}
