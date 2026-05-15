# consumers/dev/main.tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

provider "google" {
  project = "cge-compliance-labs"  # CHANGE THIS!
  region  = "us-central1"
}

# Use the secure template!
module "data_bucket" {
  source = "../../modules/compliant-gcs-bucket"

  gcp_project        = "cge-compliance-labs"  # CHANGE THIS!
  project_label      = "cgep-lab"
  environment        = "dev"
  retention_days     = 30
  bucket_name_suffix = "gideon-dev-001"
}

# Show the security proof
output "attestation" { value = module.data_bucket.compliance_attestation }
output "bucket_url"  { value = module.data_bucket.bucket_url }