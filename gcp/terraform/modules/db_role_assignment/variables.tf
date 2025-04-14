variable "project_id" {
  description = "The GCP project ID"
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
      database_role_assignment = optional(object({
        readonly  = optional(list(string), [])
        readwrite = optional(list(string), [])
        admin     = optional(list(string), [])
      }), {})
    }))
  }))
  default = []
}
