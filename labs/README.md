\# Lab 3.3: Writing Compliance Policies in Rego (GCP)



\## Overview

Automated compliance checking using Open Policy Agent (OPA) and Rego policy language. Policies scan Terraform plans BEFORE deployment to catch violations early.



\## Policies Implemented



\### SC-28: Encryption at Rest

\- \*\*Control:\*\* NIST 800-53 SC-28

\- \*\*Checks:\*\* All GCS buckets must use customer-managed encryption keys (CMEK)

\- \*\*Severity:\*\* High

\- \*\*Remediation:\*\* Add `encryption { default\_kms\_key\_name = ... }` block



\### AC-3: Access Enforcement

\- \*\*Control:\*\* NIST 800-53 AC-3

\- \*\*Checks:\*\* 

&#x20; - GCS buckets must have uniform access control and public access prevention

&#x20; - Firewalls cannot expose management ports (22, 3389) to 0.0.0.0/0

\- \*\*Severity:\*\* Critical

\- \*\*Remediation:\*\* 

&#x20; - Buckets: Set `uniform\_bucket\_level\_access=true` and `public\_access\_prevention="enforced"`

&#x20; - Firewalls: Narrow source ranges or remove rule



\### CM-6: Configuration Settings

\- \*\*Control:\*\* NIST 800-53 CM-6

\- \*\*Checks:\*\* All taggable resources must have 4 required labels

&#x20; - `project`

&#x20; - `environment`

&#x20; - `managed\_by`

&#x20; - `compliance\_scope`

\- \*\*Severity:\*\* Medium

\- \*\*Remediation:\*\* Add missing labels to resource



\## Test Results



\*\*All tests passing:\*\* 6/6 ✅



```bash

opa test -v policies/

\# PASS: 6/6

```



\## Real Violations Detected



Against our test Terraform plan:

\- \*\*AC-3:\*\* 2 violations (open firewall + public bucket)

\- \*\*CM-6:\*\* 1 violation (missing labels)

\- \*\*SC-28:\*\* Monitoring encryption configuration



\## Architecture

Terraform Code
↓
terraform plan -out=tfplan
↓
terraform show -json tfplan > plan.json
↓
OPA Evaluates Policies Against plan.json
↓
Violations Detected → BLOCK DEPLOYMENT
↓
Developer Fixes Issues
↓
Re-run Policy Check
↓
All Pass → ALLOW DEPLOYMENT ✅

## Files

policies/
├── sc28_encryption.rego      # Encryption policy
├── ac3_no_public.rego        # Access control policy
├── cm6_required_tags.rego    # Required labels policy
└── tests/
├── sc28_encryption_test.rego
├── ac3_no_public_test.rego
└── cm6_required_tags_test.rego
terraform/
├── main.tf                    # Test infrastructure (good + bad resources)
├── terraform.tfvars
└── plan.json                  # Generated plan for policy evaluation
evidence/
├── opa-test-results.json      # Test results
└── policy-check-summary.txt   # Violations found

## Usage

### Run All Tests
```bash
opa test -v policies/
```

### Check Individual Policies
```bash
opa eval -d policies -i terraform/plan.json data.compliance.sc28.deny --format=pretty
opa eval -d policies -i terraform/plan.json data.compliance.ac3.deny --format=pretty
opa eval -d policies -i terraform/plan.json data.compliance.cm6.deny --format=pretty
```

### Generate New Plan
```bash
cd terraform
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
```

## Key Learnings

1. **Shift Left:** Catch compliance issues before deployment
2. **Automated Checks:** No manual review needed for basic violations
3. **Developer-Friendly:** Clear error messages with exact resource names
4. **Framework-Agnostic:** Same Rego policies work across cloud providers
5. **CI/CD Ready:** Policies run in seconds, perfect for pipelines

## Real-World Impact

**Traditional Approach:**
- Deploy → Audit finds issue → Emergency fix → Downtime
- **Time to fix:** Days/weeks

**Policy-as-Code Approach:**
- Write code → Policy blocks violation → Fix before deploy
- **Time to fix:** Minutes

## How This Feeds the Capstone

These Rego policies become the gates in the CI/CD pipeline (Lab 4.3). When developers open pull requests, GitHub Actions runs these policies against the Terraform plan. If violations are found, the PR is blocked until fixed. This creates an automated compliance workflow where infrastructure cannot be deployed unless it passes all policy checks.




