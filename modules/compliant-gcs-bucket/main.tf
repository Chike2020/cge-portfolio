# main.tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

# These 4 labels are REQUIRED and can't be removed
locals {
  required_labels = {
    project          = var.project_label
    environment      = var.environment
    managed_by       = "terraform"
    compliance_scope = "cge-p-lab"
  }

  effective_labels = merge(var.labels, local.required_labels)
  bucket_name      = "${var.project_label}-${var.environment}-${var.bucket_name_suffix}"
  keyring_id       = "${var.bucket_name_suffix}-ring"
  key_id           = "${var.bucket_name_suffix}-key"
}

# Get the Google Cloud Storage service account
data "google_storage_project_service_account" "gcs" {
  project = var.gcp_project
}

# Create an encryption key ring (like a keychain for keys)
resource "google_kms_key_ring" "ring" {
  name     = local.keyring_id
  location = var.kms_location
  project  = var.gcp_project
}

# Create the actual encryption key (rotates every 90 days)
resource "google_kms_crypto_key" "key" {
  name            = local.key_id
  key_ring        = google_kms_key_ring.ring.id
  rotation_period = "7776000s"  # 90 days in seconds

  lifecycle {
    prevent_destroy = false
  }
}

# Give Google Cloud Storage permission to use this key
resource "google_kms_crypto_key_iam_member" "gcs_encrypter" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

# Create the secure storage bucket
resource "google_storage_bucket" "bucket" {
  name     = local.bucket_name
  project  = var.gcp_project
  location = var.location

  # SECURITY SETTINGS (locked in - users can't change these!)
  uniform_bucket_level_access = true      # Consistent access control
  public_access_prevention    = "enforced" # No public access allowed

  # Keep old versions of files
  versioning { enabled = true }

  # Use our custom encryption key
  encryption {
    default_kms_key_name = google_kms_crypto_key.key.id
  }

  # Keep files for a minimum number of days
  retention_policy {
    retention_period = var.retention_days * 86400  # days to seconds
    is_locked        = false
  }

  # Apply all the required labels
  labels = local.effective_labels

  depends_on = [google_kms_crypto_key_iam_member.gcs_encrypter]
}