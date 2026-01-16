output "role_definitions" {
  value = {
    for filename, path in local.sql_scripts :
    trimsuffix(filename, ".sql") => {
      gcs_uri = "gs://${var.target_bucket}/${filename}"
      md5hash = filemd5(path)
    }
  }
  description = "Combined output with both URIs and content hashes"
}

output "target_bucket" {
  description = "The target bucket name"
  value       = var.target_bucket
}
