output "instances" {
  description = "The name, id, and location of the Cloud Tasks queue"
  value       = { for k, v in google_cloud_tasks_queue.cloud_tasks_queue : k => {
    name = v.name
    id = v.id
    location = v.location
  } }
}