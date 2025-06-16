output "queue_name" {
  description = "The name of the Cloud Tasks queue"
  value       = google_cloud_tasks_queue.cloud_tasks_queue.name
}

output "queue_id" {
  description = "The ID of the Cloud Tasks queue"
  value       = google_cloud_tasks_queue.cloud_tasks_queue.id
}

output "queue_location" {
  description = "The location of the Cloud Tasks queue"
  value       = google_cloud_tasks_queue.cloud_tasks_queue.location
}

output "queue_state" {
  description = "The current state of the Cloud Tasks queue"
  value       = google_cloud_tasks_queue.cloud_tasks_queue.state
}