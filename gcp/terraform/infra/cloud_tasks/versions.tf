terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }
    tfe = {
        source  = "hashicorp/tfe"
        version = "~> 0.76.0" # Use the latest version
      }
  }
  required_version = "1.15.2"
}