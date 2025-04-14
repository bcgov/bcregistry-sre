terraform {
  cloud {
    organization = "BCRegistry"
    workspaces {
      name = "gcp-iam"
    }
  }
}

provider "google" {
  project = null
  region  = var.region
  impersonate_service_account = local.service_account_email
}

provider "tfe" {
}

data "tfe_organization" "current" {
  name = "BCRegistry"
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
  for_each = var.projects

  source           = "./modules/iam"
  project_id       = each.value.project_id
  env              = lookup(var.environments, each.value.env, local.default_environment)
  service_accounts = each.value.service_accounts
  custom_roles     = each.value.custom_roles
  global_custom_roles = var.global_custom_roles
}

module "pam" {
  for_each = var.projects

  source   = "./modules/pam"

  parent_id             = each.value.project_id
  organization_id       = data.tfe_organization.current.id
  pam_bindings          = each.value.pam_bindings
  principals            = var.default_principals
  env                   = lookup(var.environments, each.value.env, local.default_environment)
}

module "db_roles" {
  source       = "./modules/db_roles"
  target_bucket = "common-tools-sql"
}

module "db_role_management" {
  for_each = var.projects

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
  for_each = var.projects

  source = "./modules/db_role_assignment"

  project_id  = each.value.project_id
  region = var.region
  bucket_name = module.db_roles.target_bucket
  service_account_email = var.TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL

  global_assignments       = var.global_database_role_assignment
  environment_assignments  = try(lookup(var.environments, each.value.env, local.default_environment).database_role_assignment, {})
  instances               = try(each.value.instances, {})
}
