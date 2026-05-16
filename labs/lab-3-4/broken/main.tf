terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "us-east-1"
  # NO default_tags - violates CM-6!
}

# BROKEN: Bucket with NO encryption
resource "aws_s3_bucket" "bad_no_encryption" {
  bucket = "lab34-bad-no-encryption-gokech"
}

# BROKEN: Bucket with NO public access block
resource "aws_s3_bucket" "bad_no_pab" {
  bucket = "lab34-bad-no-pab-gokech"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bad_no_pab" {
  bucket = aws_s3_bucket.bad_no_pab.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# BROKEN: Bucket with NO tags
resource "aws_s3_bucket" "bad_no_tags" {
  bucket = "lab34-bad-no-tags-gokech"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bad_no_tags" {
  bucket = aws_s3_bucket.bad_no_tags.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bad_no_tags" {
  bucket                  = aws_s3_bucket.bad_no_tags.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}