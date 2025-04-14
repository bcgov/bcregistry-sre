variable "project_id" {
  description = "The project ID where the databases exist"
  type        = string
}

variable "region" {
  description = "The project ID where the databases exist"
  type        = string
}

variable "instances" {
  description = "List of database instances and their associated databases to manage roles for"
  type = list(object({
    instance = string
    databases = list(object({
      db_name = string
      owner   = optional(string)
      roles   = list(string)
      database_role_assignment = optional(object({
        readonly  = optional(list(string), [])
        readwrite = optional(list(string), [])
        admin     = optional(list(string), [])
      }), {})
    }))
  }))
  default = []
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

variable "service_account_email" {
  description = "The service account email address that Terraform Cloud will use to authenticate to Google Cloud"
  type        = string
}
