# terraform/main.tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

provider "google" {
  project = var.gcp_project
  region  = "us-central1"
}

variable "gcp_project" { 
  type = string 
}

# Create encryption key for compliant buckets
resource "google_kms_key_ring" "ring" {
  name     = "lab33-ring"
  location = "us-central1"
}

resource "google_kms_crypto_key" "key" {
  name     = "lab33-key"
  key_ring = google_kms_key_ring.ring.id
}

# GOOD BUCKET - Follows all rules ✅
resource "google_storage_bucket" "good" {
  name                        = "${var.gcp_project}-lab33-good"
  location                    = "us-central1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  encryption { 
    default_kms_key_name = google_kms_crypto_key.key.id 
  }

  labels = {
    project          = "lab33"
    environment      = "dev"
    managed_by       = "terraform"
    compliance_scope = "cge-p-lab"
  }
}

# BAD BUCKET #1 - No encryption ❌
resource "google_storage_bucket" "bad_no_cmek" {
  name                        = "${var.gcp_project}-lab33-bad-no-cmek"
  location                    = "us-central1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  # Missing encryption block!

  labels = {
    project          = "lab33"
    environment      = "dev"
    managed_by       = "terraform"
    compliance_scope = "cge-p-lab"
  }
}

# BAD BUCKET #2 - Public access allowed ❌
resource "google_storage_bucket" "bad_public" {
  name                        = "${var.gcp_project}-lab33-bad-public"
  location                    = "us-central1"
  uniform_bucket_level_access = false  # Wrong!
  public_access_prevention    = "inherited"  # Wrong!

  encryption { 
    default_kms_key_name = google_kms_crypto_key.key.id 
  }

  labels = {
    project          = "lab33"
    environment      = "dev"
    managed_by       = "terraform"
    compliance_scope = "cge-p-lab"
  }
}

# BAD BUCKET #3 - Missing labels ❌
resource "google_storage_bucket" "bad_no_labels" {
  name                        = "${var.gcp_project}-lab33-bad-no-labels"
  location                    = "us-central1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  encryption { 
    default_kms_key_name = google_kms_crypto_key.key.id 
  }

  # Missing labels!
}

# Create a network for firewall test
resource "google_compute_network" "demo" {
  name                    = "lab33-demo"
  auto_create_subnetworks = false
}

# BAD FIREWALL - SSH open to the world ❌
resource "google_compute_firewall" "open_ssh" {
  name          = "lab33-open-ssh"
  network       = google_compute_network.demo.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]  # From anywhere!
  
  allow { 
    protocol = "tcp"
    ports    = ["22"]  # SSH port open!
  }
}