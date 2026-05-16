# policies/cm6_required_tags_aws.rego
# METADATA
# title: "CM-6 - Configuration Settings (AWS required tags)"
# custom:
#   control_id: "CM-6"
#   framework: "nist-800-53"
#   severity: "medium"

package compliance.cm6_aws

import rego.v1

# Required tags (note: AWS uses different casing than GCP labels)
required := {"Project", "Environment", "ManagedBy", "ComplianceScope"}

# Types that should have tags
labelable_type(t) if t == "aws_s3_bucket"
labelable_type(t) if t == "aws_dynamodb_table"
labelable_type(t) if t == "aws_lambda_function"
labelable_type(t) if t == "aws_kms_key"

# Check all resources have required tags
deny contains msg if {
    resource := all_resources[_]
    labelable_type(resource.type)
    provided := tag_keys(resource)
    missing := required - provided
    count(missing) > 0
    msg := sprintf(
        "[CM-6] %s: missing required tags %v. Add the missing tags or use provider default_tags.",
        [resource.address, sort_array(missing)],
    )
}

# Get all resources
all_resources contains r if {
    some r in input.planned_values.root_module.resources
}

# Get tag keys from resource (AWS uses tags_all with default_tags)
tag_keys(resource) := keys if {
    resource.values.tags_all
    keys := {k | resource.values.tags_all[k]}
}

tag_keys(resource) := keys if {
    not resource.values.tags_all
    resource.values.tags
    keys := {k | resource.values.tags[k]}
}

tag_keys(resource) := set() if {
    not resource.values.tags_all
    not resource.values.tags
}

# Helper to sort arrays
sort_array(s) := sorted if {
    sorted := sort([x | some x in s])
}