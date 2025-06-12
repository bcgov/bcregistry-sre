variable "project_id" {
  description = "The ID of the project where the Cloud Tasks queue will be created"
  type        = string
}

variable "location" {
  description = "The location where the Cloud Tasks queue will be created"
  type        = string
}

variable "queue_name" {
  description = "The name of the Cloud Tasks queue"
  type        = string
}

variable "max_dispatches_per_second" {
  description = "The maximum number of tasks that can be dispatched per second"
  type        = number
  default     = 5
}

variable "max_concurrent_dispatches" {
  description = "The maximum number of concurrent tasks that can be dispatched"
  type        = number
  default     = 100
}

variable "max_attempts" {
  description = "The maximum number of attempts for a task"
  type        = number
  default     = 3
}

variable "max_retry_duration" {
  description = "The maximum duration for retrying a task"
  type        = string
  default     = "60s"
}

variable "min_backoff" {
  description = "The minimum backoff duration between retries"
  type        = string
  default     = "5s"
}

variable "max_backoff" {
  description = "The maximum backoff duration between retries"
  type        = string
  default     = "5s"
}

variable "max_doublings" {
  description = "The maximum number of times that the backoff duration can be doubled before reaching the maximum backoff"
  type        = number
  default     = 0
}

variable "sampling_ratio" {
  description = "The sampling ratio for Stackdriver logging"
  type        = number
  default     = 1.0
} 