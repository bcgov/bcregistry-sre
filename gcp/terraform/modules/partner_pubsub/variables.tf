variable "project_id" {
  description = "GCP project where partner topics and IAM live."
  type        = string
}

variable "env_suffix" {
  description = "Environment identifier appended to topic names (dev / test / prod). Must match ENVIRONMENT_NAME on the sbc-pay side so the routing convention lines up."
  type        = string
}

variable "partners" {
  description = <<-EOT
    Per-partner configuration. The map key is the partner's code (lowercase);
    it drives topic naming via the convention `pay-events-<key>-<env_suffix>`.

    Fields:
      subscriber_members  IAM members granted `pubsub.subscriber` + `pubsub.viewer` on the
                          partner's topic. Each entry is a fully-qualified IAM member string.
                          Empty list is allowed if the partner isn't consuming via
                          cross-project subscription yet.
      labels              Optional labels applied to the topic + DLQ topic.
  EOT
  type = map(object({
    subscriber_members = list(string)
    labels             = optional(map(string), {})
  }))
  default = {}
}

variable "publisher_members" {
  description = "IAM members granted `pubsub.publisher` on every partner topic in this project. "
  type        = list(string)
  default     = []
}
