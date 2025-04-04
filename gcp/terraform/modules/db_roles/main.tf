variable "target_bucket" {
  description = "Name of the GCS bucket where SQL role definitions should be stored"
  type        = string
}

locals {
  sql_scripts = {
    "readonly.sql"  = "${path.module}/scripts/readonly.sql"
    "readwrite.sql" = "${path.module}/scripts/readwrite.sql"
    "admin.sql"     = "${path.module}/scripts/admin.sql"
  }
}

resource "google_storage_bucket_object" "sql_files" {
  for_each = local.sql_scripts

  name   = each.key
  bucket = var.target_bucket
  source = each.value

}

# Optional outputs
output "uploaded_files" {
  value = {
    for k, v in google_storage_bucket_object.sql_files : k => v.self_link
  }
  description = "Map of uploaded SQL files and their GCS URLs"
}
