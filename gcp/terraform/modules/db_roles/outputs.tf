output "role_definitions" {
  value = {
    for filename, obj in google_storage_bucket_object.sql_files :
    trimsuffix(filename, ".sql") => {
      gcs_uri  = "gs://${obj.bucket}/${obj.name}"
      md5hash  = obj.md5hash
    }
  }
  description = "Combined output with both URIs and content hashes"
}

output "target_bucket" {
  description = "The target bucket name"
  value       = var.target_bucket
}
