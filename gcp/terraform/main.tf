terraform {
  backend "gcs" {
    bucket = "common-tools-terraform-state"
    prefix = "iam"
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
  default_environment = {
    database_role_assignment = {
      readonly  = []
      readwrite = []
      admin     = []
    }
    environment_custom_roles = {}
    pam_bindings            = []
  }
  service_account_email = var.TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL
}

module "iam" {
  for_each = local.projects

  source           = "./modules/iam"
  project_id       = each.value.project_id
  env              = lookup(var.environments, each.value.env, local.default_environment)
  service_accounts = each.value.service_accounts
  custom_roles     = each.value.custom_roles
  global_custom_roles = var.global_custom_roles
}

module "pam" {
  for_each = local.projects

  source   = "./modules/pam"

  parent_id             = each.value.project_id
  # organization_id = data.google_organization.current.id
  organization_id = "organizations/${var.org_id}"
  pam_bindings          = each.value.pam_bindings
  principals            = var.default_principals
  env                   = lookup(var.environments, each.value.env, local.default_environment)
}

module "db_roles" {
  source       = "./modules/db_roles"
  target_bucket = "common-tools-sql"
}

module "db_role_management" {
  for_each = local.projects

  source      = "./modules/db_role_management"
  project_id  = each.value.project_id
  instances   = each.value.instances
  bucket_name = module.db_roles.target_bucket
  service_account_email = var.TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL
  region = var.region

  # Pass the role definitions as input variable
  role_definitions = {
    for role, def in module.db_roles.role_definitions :
    role => {
      gcs_uri  = def.gcs_uri
      md5hash  = def.md5hash
    }
  }

  depends_on = [module.db_roles]
}


module "sql_iam_users" {
  for_each = local.projects

  source = "./modules/db_role_assignment"

  project_id  = each.value.project_id
  region      = var.region
  bucket_name = module.db_roles.target_bucket
  service_account_email = var.TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL

  global_assignments      = var.global_database_role_assignment
  environment_assignments = try(lookup(var.environments, each.value.env, local.default_environment).database_role_assignment, {})
  instances               = try(each.value.instances, [])
  all_service_account_emails = module.iam[each.key].service_account_emails

  depends_on = [
    module.db_role_management,
    module.iam
  ]
}


module "cloud_tasks" {
  for_each = {
    for instance in flatten([
      for project in local.projects : [
        for instance in try(project.cloud_tasks.instances, []) : {
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

  source = "./modules/cloud_tasks"

  project_id = each.value.project_id
  location   = each.value.location
  queue_name = each.value.queue_name
  max_dispatches_per_second = each.value.max_dispatches_per_second
  max_concurrent_dispatches = each.value.max_concurrent_dispatches
  max_attempts = each.value.max_attempts
  max_retry_duration = each.value.max_retry_duration
  min_backoff = each.value.min_backoff
  max_backoff = each.value.max_backoff
  max_doublings = each.value.max_doublings
  sampling_ratio = each.value.sampling_ratio
}