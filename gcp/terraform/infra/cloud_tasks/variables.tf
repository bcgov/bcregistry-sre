variable "TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL" {
  description = "The service account email address that Terraform Cloud will use to authenticate to Google Cloud"
  type        = string
}

variable "region" {
  description = "The region where the Cloud Tasks queue will be created"
  type        = string
  default     = "northamerica-northeast1"
}

variable "dev_projects" {
  type = map(object({
    project_id = string
    env        = string
    instances = list(object({
      instance = string
      max_dispatches_per_second = optional(number, 500)
      max_concurrent_dispatches = optional(number, 100)
      max_attempts = optional(number, 3)
      max_retry_duration = optional(string, "3600s")
      min_backoff = optional(string, "0.1s")
      max_backoff = optional(string, "3600s")
      max_doublings = optional(number, 16)
      sampling_ratio = optional(number, 1.0)
    }))
  }))
  default = {}
  description = "Configuration for development projects and their Cloud Tasks queues"
}

variable "test_projects" {
  type = map(object({
    project_id = string
    env        = string
    instances = list(object({
      instance = string
      max_dispatches_per_second = optional(number, 500)
      max_concurrent_dispatches = optional(number, 100)
      max_attempts = optional(number, 3)
      max_retry_duration = optional(string, "3600s")
      min_backoff = optional(string, "0.1s")
      max_backoff = optional(string, "3600s")
      max_doublings = optional(number, 16)
      sampling_ratio = optional(number, 1.0)
    }))
  }))
  default = {}
  description = "Configuration for development projects and their Cloud Tasks queues"
}

variable "prod_projects" {
  type = map(object({
    project_id = string
    env        = string
    instances = list(object({
      instance = string
      max_dispatches_per_second = optional(number, 500)
      max_concurrent_dispatches = optional(number, 100)
      max_attempts = optional(number, 3)
      max_retry_duration = optional(string, "3600s")
      min_backoff = optional(string, "0.1s")
      max_backoff = optional(string, "3600s")
      max_doublings = optional(number, 16)
      sampling_ratio = optional(number, 1.0)
    }))
  }))
  default = {}
  description = "Configuration for development projects and their Cloud Tasks queues"
}

variable "other_projects" {
  type = map(object({
    project_id = string
    env        = string
    instances = list(object({
      instance = string
      max_dispatches_per_second = optional(number, 500)
      max_concurrent_dispatches = optional(number, 100)
      max_attempts = optional(number, 3)
      max_retry_duration = optional(string, "3600s")
      min_backoff = optional(string, "0.1s")
      max_backoff = optional(string, "3600s")
      max_doublings = optional(number, 16)
      sampling_ratio = optional(number, 1.0)
    }))
  }))
  default = {}
  description = "Configuration for development projects and their Cloud Tasks queues"
}

# Merge all project maps into the main projects variable
locals {
  projects = merge(
    var.dev_projects,
    var.test_projects,
    var.prod_projects,
    var.other_projects
  )
}