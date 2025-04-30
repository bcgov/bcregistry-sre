variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The project ID where the databases exist"
  type        = string
}

variable "global_assignments" {
  description = "Global database role assignments"
  type = object({
    readonly  = optional(list(string), [])
    readwrite = optional(list(string), [])
    admin     = optional(list(string), [])
  })
  default = {}
}

variable "environment_assignments" {
  description = "Environment-level database role assignments"
  type = object({
    readonly  = optional(list(string), [])
    readwrite = optional(list(string), [])
    admin     = optional(list(string), [])
  })
  default = {}
}

variable "instances" {
  description = "List of instances and their databases"
  type = list(object({
    instance = string
    databases = list(object({
      db_name    = string
      roles      = list(string)
      owner      = optional(string)
      agent      = optional(string)
      database_role_assignment = optional(object({
        readonly  = optional(list(string), [])
        readwrite = optional(list(string), [])
        admin     = optional(list(string), [])
      }), {})
    }))
  }))
  default = []
}

variable "cloud_function_url" {
  description = "The HTTPS URL of the Cloud Function that assigns db roles"
  type        = string
  default     = "https://northamerica-northeast1-c4hnrd-tools.cloudfunctions.net/db-roles-assign"
}

variable "service_account_email" {
  description = "The service account email address that Terraform Cloud will use to authenticate to Google Cloud"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket containing role definitions"
  type        = string
}
