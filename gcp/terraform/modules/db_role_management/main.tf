locals {
  instance_keys = toset([for db in var.databases : db.instance])
  service_accounts = {
    for key in local.instance_keys :
    key => data.google_sql_database_instance.instances[key].service_account_email_address
  }
}

data "google_sql_database_instance" "instances" {
  for_each = local.instance_keys

  name    = each.key
  project = var.project_id
}

resource "google_storage_bucket_iam_member" "cloudsql_bucket_access" {
  for_each = local.service_accounts

  bucket = var.bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${each.value}"
}

resource "null_resource" "apply_roles" {
  for_each = var.databases

  triggers = {
    # Combined hash of all role scripts (properly formatted)
    gcs_content_md5 = md5(join("", [
      for role in each.value.roles :
      var.role_definitions[role].md5hash
    ]))

    instance_name = each.value.instance
    db_name      = each.value.db_name
    project_id   = var.project_id

    # All URIs stored as JSON
    gcs_uris = jsonencode({
      for role in each.value.roles :
      role => var.role_definitions[role].gcs_uri
    })

    all_roles = join(",", each.value.roles)

    cloud_function_url = var.cloud_function_url
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      %{ for role in split(",", self.triggers.all_roles) ~}
      curl -X POST "${self.triggers.cloud_function_url}" \
        -H "Content-Type: application/json" \
        -d '{"instance_name":"${self.triggers.instance_name}", "gcs_uri":"${jsondecode(self.triggers.gcs_uris)[role]}", "database":"${self.triggers.db_name}", "owner":"${each.value.owner}"}'
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
