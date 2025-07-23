terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.44.0"
    }
    tfe = {
        source  = "hashicorp/tfe"
        version = "~> 0.68.0" # Use the latest version
      }
  }
  required_version = "= 1.10.5"
}