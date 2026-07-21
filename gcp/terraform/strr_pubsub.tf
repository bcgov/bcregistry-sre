locals {
  manage_strr_sandbox_bulk_validation_response = terraform.workspace == "other"
}

data "google_pubsub_topic" "strr_sandbox_bulk_validation_response" {
  count = local.manage_strr_sandbox_bulk_validation_response ? 1 : 0

  name    = "strr-bulk-validation-response-sandbox"
  project = "bcrbk9-tools"
}

resource "google_pubsub_subscription" "strr_sandbox_bulk_validation_response" {
  count = local.manage_strr_sandbox_bulk_validation_response ? 1 : 0

  name    = "strr-bulk-validation-response-sandbox-sub"
  project = "bcrbk9-tools"
  topic   = data.google_pubsub_topic.strr_sandbox_bulk_validation_response[0].id

  ack_deadline_seconds       = 30
  message_retention_duration = "604800s"
  retain_acked_messages      = false

  expiration_policy {
    ttl = ""
  }

  dead_letter_policy {
    dead_letter_topic     = "projects/bcrbk9-tools/topics/strr-bulk-validation-response-dlq-sandbox"
    max_delivery_attempts = 5
  }

  push_config {
    push_endpoint = "https://batch-permit-listener-sandbox-865508335279.northamerica-northeast1.run.app/bulk-validation-response"

    attributes = {
      x-goog-version = "v1"
    }

    oidc_token {
      service_account_email = "sa-pubsub@bcrbk9-tools.iam.gserviceaccount.com"
      audience              = "https://batch-permit-listener-sandbox-865508335279.northamerica-northeast1.run.app"
    }
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

# Adopt the Sandbox subscription created during REGBACKLOG-333.
import {
  for_each = local.manage_strr_sandbox_bulk_validation_response ? toset([
    "projects/bcrbk9-tools/subscriptions/strr-bulk-validation-response-sandbox-sub"
  ]) : toset([])

  to = google_pubsub_subscription.strr_sandbox_bulk_validation_response[0]
  id = each.value
}
