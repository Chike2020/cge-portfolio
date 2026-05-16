# policies/sc28_encryption_aws.rego
# METADATA
# title: "SC-28 - Encryption at Rest (AWS S3)"
# description: "Every aws_s3_bucket must have an aws_s3_bucket_server_side_encryption_configuration that references it."
# custom:
#   control_id: "SC-28"
#   framework: "nist-800-53"
#   severity: "high"
#   remediation: "Add aws_s3_bucket_server_side_encryption_configuration { bucket = aws_s3_bucket.<name>.id ... } for the bucket."

package compliance.sc28_aws

import rego.v1

# Find all S3 buckets
deny contains msg if {
    bucket := bucket_addresses[_]
    not has_encryption(bucket)
    msg := sprintf(
        "[SC-28] %s: aws_s3_bucket has no matching aws_s3_bucket_server_side_encryption_configuration. Add one referencing this bucket.",
        [bucket],
    )
}

# Get all bucket addresses
bucket_addresses contains addr if {
    some r in input.configuration.root_module.resources
    r.type == "aws_s3_bucket"
    addr := sprintf("aws_s3_bucket.%s", [r.name])
}

# Check if bucket has encryption configuration
has_encryption(bucket_addr) if {
    some r in input.configuration.root_module.resources
    r.type == "aws_s3_bucket_server_side_encryption_configuration"
    some ref in r.expressions.bucket.references
    references_bucket(ref, bucket_addr)
}

# Check if encryption references the bucket
references_bucket(ref, bucket_addr) if ref == bucket_addr
references_bucket(ref, bucket_addr) if ref == sprintf("%s.id", [bucket_addr])
references_bucket(ref, bucket_addr) if ref == sprintf("%s.bucket", [bucket_addr])