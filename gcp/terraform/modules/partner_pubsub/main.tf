locals {
  # topic names are derived from partner code + env. 
  # DevOps sets `<CORP_TYPE>_PAY_TOPIC` in 1Password to the topic name generated here.
  topic_name_prefix = "pay-events"

  topics = {
    for code, cfg in var.partners :
    code => {
      topic_name = "${local.topic_name_prefix}-${code}-${var.env_suffix}"
      dlq_name   = "${local.topic_name_prefix}-${code}-${var.env_suffix}-dlq"
      labels     = cfg.labels
    }
  }

  publisher_bindings = flatten([
    for code, cfg in var.partners : [
      for member in var.publisher_members : {
        code   = code
        member = member
      }
    ]
  ])

  # Subscribers get subscriber + viewer roles so they can create + describe subscriptions cross-project.
  subscriber_bindings = flatten([
    for code, cfg in var.partners : [
      for member in cfg.subscriber_members : {
        code   = code
        member = member
      }
    ]
  ])
}

resource "google_pubsub_topic" "events" {
  for_each = local.topics

  project = var.project_id
  name    = each.value.topic_name

  labels = merge(
    {
      partner = each.key
      purpose = "pay-events"
      env     = var.env_suffix
    },
    each.value.labels
  )
}

resource "google_pubsub_topic" "dlq" {
  for_each = local.topics

  project = var.project_id
  name    = each.value.dlq_name

  labels = merge(
    {
      partner = each.key
      purpose = "pay-events-dlq"
      env     = var.env_suffix
    },
    each.value.labels
  )
}

# Pull subscription on the DLQ so operators can inspect failed messages
resource "google_pubsub_subscription" "dlq_pull" {
  for_each = local.topics

  project = var.project_id
  name    = "${each.value.dlq_name}-pull"
  topic   = google_pubsub_topic.dlq[each.key].id

  # Keep failed messages around long enough that a Monday-morning triage still
  # has data from a Friday-evening incident.
  message_retention_duration = "604800s" # 7 days
  ack_deadline_seconds       = 60
}

resource "google_pubsub_topic_iam_member" "publisher" {
  for_each = {
    for b in local.publisher_bindings :
    "${b.code}-${b.member}" => b
  }

  project = var.project_id
  topic   = google_pubsub_topic.events[each.value.code].name
  role    = "roles/pubsub.publisher"
  member  = each.value.member
}

resource "google_pubsub_topic_iam_member" "subscriber" {
  for_each = {
    for b in local.subscriber_bindings :
    "${b.code}-${b.member}" => b
  }

  project = var.project_id
  topic   = google_pubsub_topic.events[each.value.code].name
  role    = "roles/pubsub.subscriber"
  member  = each.value.member
}

resource "google_pubsub_topic_iam_member" "viewer" {
  for_each = {
    for b in local.subscriber_bindings :
    "${b.code}-${b.member}" => b
  }

  project = var.project_id
  topic   = google_pubsub_topic.events[each.value.code].name
  role    = "roles/pubsub.viewer"
  member  = each.value.member
}
