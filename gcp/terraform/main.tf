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
}

provider "tfe" {
}

data "tfe_organization" "current" {
  name = "BCRegistry"
}

locals {
  default_environment = {
    environment_custom_roles = {}
    pam_bindings            = []
  }
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
