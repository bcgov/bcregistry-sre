output "topic_names" {
  description = "Map of partner code to events topic name. Feed these into 1Password (`<CORP_TYPE>_PAY_TOPIC` fields)."
  value = {
    for code, t in local.topics : code => t.topic_name
  }
}

output "dlq_topic_names" {
  description = "Map of partner code to DLQ topic name."
  value = {
    for code, t in local.topics : code => t.dlq_name
  }
}

output "topic_ids" {
  description = "Map of partner code to fully-qualified events topic ID."
  value = {
    for code, t in google_pubsub_topic.events : code => t.id
  }
}
