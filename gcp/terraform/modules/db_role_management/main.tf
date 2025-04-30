locals {
  # Flatten the instances structure to get all unique instance names
  instance_keys = toset(flatten([
    for instance in var.instances : instance.instance
  ]))

  # Get service account emails for each instance
  service_accounts = {
    for key in local.instance_keys :
    key => data.google_sql_database_instance.instances[key].service_account_email_address
  }

  # Create a flattened list of all databases with their instance info
  all_databases = flatten([
    for instance in var.instances : [
      for db in instance.databases : {
        instance_name = instance.instance
        db_name       = db.db_name
        owner         = try(db.owner, null)
        agent         = try(db.agent, null)
        roles         = db.roles
      }
    ]
  ])
}

data "google_sql_database_instance" "instances" {
  for_each = local.instance_keys
  name     = each.key
  project  = var.project_id
}

resource "google_storage_bucket_iam_member" "cloudsql_bucket_access" {
  for_each = local.service_accounts
  bucket   = var.bucket_name
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${each.value}"
}

data "google_service_account_id_token" "invoker" {
  target_audience = var.cloud_function_url
  target_service_account = var.service_account_email
}

resource "null_resource" "apply_roles" {
  for_each = { for idx, db in local.all_databases :
    "${db.instance_name}.${db.db_name}" => db
  }

  depends_on = [google_storage_bucket_iam_member.cloudsql_bucket_access]

  triggers = {
    # test trigger
    # run_at = timestamp()
    gcs_content_md5 = md5(join("", [
      for role in each.value.roles :
      var.role_definitions[role].md5hash
    ]))
    instance_name = "${var.project_id}:${var.region}:${each.value.instance_name}"
    db_name      = each.value.db_name
    project_id   = var.project_id
    gcs_uris     = jsonencode({
      for role in each.value.roles :
      role => var.role_definitions[role].gcs_uri
    })
    all_roles = join(",", each.value.roles)
  }

provisioner "local-exec" {
  when    = create
  command = <<-EOT
    set -ex
    %{ for role in split(",", self.triggers.all_roles) ~}
    echo "Applying role: ${role}"

    PAYLOAD=$(jq -n \
      --arg instance "${self.triggers.instance_name}" \
      --arg uri "${jsondecode(self.triggers.gcs_uris)[role]}" \
      --arg db "${self.triggers.db_name}" \
      --arg owner "${each.value.owner}" \
      --arg agent "${coalesce(each.value.agent, each.value.owner)}" \
      '{
        instance_name: $instance,
        gcs_uri: $uri,
        database: $db,
        owner: $owner,
        agent: $agent
      }'
    )

    OUTPUT=$(curl -v -X POST "${var.cloud_function_url}" \
      -H "Authorization: Bearer ${data.google_service_account_id_token.invoker.id_token}" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD" \
      --fail 2>&1)

    echo "$OUTPUT"
    %{ endfor ~}
  EOT
}

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Database ${self.triggers.db_name} was deleted from instance ${self.triggers.instance_name}"
    EOT
  }
}
