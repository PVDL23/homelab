variable "object_storage_bucket_name" {
  description = "Object Storage bucket name"
  type        = string
}

variable "homelab_project_name" {
  description = "Display name for the homelab Scaleway project"
  type        = string
}

variable "homelab_project_description" {
  description = "Description for the homelab Scaleway project"
  type        = string
}

variable "budget_limit" {
  description = "Budget limit for Scaleway billing"
  type        = number
  default     = 100
  sensitive   = true
}

variable "budget_alert_threshold" {
  description = "Threshold for the billing budget alert"
  type        = number
  default     = 80
  sensitive   = true
}

variable "budget_alert_email_addresses" {
  description = "Email addresses for the billing budget alert notifications"
  type        = list(string)
  sensitive   = true
}
