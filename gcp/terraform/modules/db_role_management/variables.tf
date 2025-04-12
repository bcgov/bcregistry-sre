variable "project_id" {
  description = "The project ID where the databases exist"
  type        = string
}

variable "databases" {
  description = "Map of databases to manage roles for"
  type = map(object({
    instance = string
    db_name  = string
    owner    = string
    roles    = list(string)
  }))
  default     = {}
}

variable "bucket_name" {
  description = "Name of the GCS bucket containing role definitions"
  type        = string
}

variable "role_definitions" {
  description = "Role definitions from db_roles module"
  type = map(object({
    gcs_uri = string
    md5hash = string
  }))
}

variable "cloud_function_url" {
  description = "The HTTPS URL of the Cloud Function that applies SQL roles"
  type        = string
  default     = "https://northamerica-northeast1-c4hnrd-tools.cloudfunctions.net/db-roles-create"
}
