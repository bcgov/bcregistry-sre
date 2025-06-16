terraform {
  backend "gcs" {
    bucket = "common-tools-terraform-state"
    prefix = "infra/cloud-tasks"
  }
}

provider "google" {
  project = null
  region  = var.region
  impersonate_service_account = local.service_account_email
}

variable "org_id" {
  default = "168766599236"
}

locals {
  location = var.region
  service_account_email = var.TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL
}

# Validate project existence before creating resources
data "google_project" "project" {
  for_each = {
    for project in local.projects : project.project_id => project
  }
  project_id = each.key
}

resource "google_cloud_tasks_queue" "cloud_tasks_queue" {
  for_each = {
    for instance in flatten([
      for project in local.projects : [
        for instance in try(project.instances, []) : {
          project_id = project.project_id
          location = var.region
          queue_name = instance.instance
          max_dispatches_per_second = instance.max_dispatches_per_second
          max_concurrent_dispatches = instance.max_concurrent_dispatches
          max_attempts = instance.max_attempts
          max_retry_duration = instance.max_retry_duration
          min_backoff = instance.min_backoff
          max_backoff = instance.max_backoff
          max_doublings = instance.max_doublings
          sampling_ratio = instance.sampling_ratio
        }
      ]
    ]) : "${instance.project_id}-${instance.queue_name}" => instance
  }

  name     = each.value.queue_name
  location = each.value.location
  project  = each.value.project_id

  rate_limits {
    max_dispatches_per_second = each.value.max_dispatches_per_second
    max_concurrent_dispatches = each.value.max_concurrent_dispatches
  }

  retry_config {
    max_attempts       = each.value.max_attempts
    max_retry_duration = each.value.max_retry_duration
    min_backoff        = each.value.min_backoff
    max_backoff        = each.value.max_backoff
    max_doublings      = each.value.max_doublings
  }

  stackdriver_logging_config {
    sampling_ratio = each.value.sampling_ratio
  }

  # Ensure project exists before creating queue
  depends_on = [data.google_project.project]
}