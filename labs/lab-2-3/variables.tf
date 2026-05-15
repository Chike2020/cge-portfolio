# variables.tf
variable "project_name" {
  type        = string
  description = "Short project identifier"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project_name))
    error_message = "project_name must be 3-21 lowercase letters/numbers/hyphens, starting with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be: dev, staging, or prod."
  }
}

variable "bucket_suffix" {
  type        = string
  description = "Optional custom suffix for bucket name"
  default     = ""
}