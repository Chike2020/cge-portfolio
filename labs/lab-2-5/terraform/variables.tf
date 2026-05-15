# variables.tf
variable "project_name" {
  type    = string
  default = "cgep-lab"
}

variable "lock_mode" {
  type        = string
  description = "GOVERNANCE for labs, COMPLIANCE for real evidence"
  default     = "GOVERNANCE"
  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.lock_mode)
    error_message = "lock_mode must be GOVERNANCE or COMPLIANCE."
  }
}

variable "retention_days" {
  type        = number
  description = "How many days to lock files"
  default     = 1
}