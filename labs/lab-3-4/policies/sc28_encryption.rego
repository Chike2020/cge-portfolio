# policies/sc28_encryption.rego
# METADATA
# title: "SC-28 - Encryption at Rest (GCS)"
# description: "Every google_storage_bucket must encrypt at rest with a customer-managed encryption key (CMEK)."
# custom:
#   control_id: "SC-28"
#   framework: "nist-800-53"
#   severity: "high"
#   remediation: "Add an encryption { default_kms_key_name = ... } block referencing a google_kms_crypto_key you control."

package compliance.sc28

import rego.v1

# Check root-level resources
deny contains msg if {
    some resource in input.planned_values.root_module.resources
    resource.type == "google_storage_bucket"
    not has_cmek(resource)
    msg := sprintf(
        "[SC-28] %s: missing customer-managed encryption key. Add encryption { default_kms_key_name = ... }.",
        [resource.address],
    )
}

# Check if bucket has encryption
has_cmek(resource) if {
    count(resource.values.encryption) > 0
    not empty_kms_key(resource.values.encryption[0])
}

# Check if encryption key is empty
empty_kms_key(enc) if enc.default_kms_key_name == ""
empty_kms_key(enc) if enc.default_kms_key_name == null