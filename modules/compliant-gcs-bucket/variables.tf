# variables.tf
variable "gcp_project" {
  type        = string
  description = "Your GCP project ID"
}

variable "location" {
  type        = string
  description = "Where to store the bucket"
  default     = "us-central1"
}

variable "kms_location" {
  type        = string
  description = "Where to store the encryption keys"
  default     = "us-central1"
}

variable "project_label" {
  type        = string
  description = "Short project name (3-21 lowercase letters/numbers/hyphens)"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project_label))
    error_message = "project_label must be 3-21 lowercase alphanumerics or hyphens, starting with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Environment: dev, staging, or prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be: dev, staging, or prod."
  }
}

variable "retention_days" {
  type        = number
  description = "How many days to keep files (1-3650)"

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 3650
    error_message = "retention_days must be between 1 and 3650."
  }

  # PRODUCTION MUST KEEP FILES FOR AT LEAST 1 YEAR!
  validation {
    condition     = var.environment != "prod" || var.retention_days >= 365
    error_message = "Production must keep files for at least 365 days!"
  }
}

variable "bucket_name_suffix" {
  type        = string
  description = "Unique identifier for this bucket (3-30 characters)"
  validation {
    condition     = can(regex("^[a-z0-9-]{3,30}$", var.bucket_name_suffix))
    error_message = "bucket_name_suffix must be 3-30 lowercase alphanumerics or hyphens."
  }
}

variable "labels" {
  type        = map(string)
  description = "Optional extra labels"
  default     = {}
}