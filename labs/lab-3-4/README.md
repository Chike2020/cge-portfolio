\# Lab 3.4: Integrating Policy-as-Code with Terraform via Conftest (AWS)



\## Overview

Cross-cloud policy library that enforces NIST 800-53 controls on both GCP and AWS infrastructure. Uses Conftest to create a fail-closed gate for CI/CD pipelines.



\## Key Achievement

\*\*Same NIST Controls, Multiple Clouds:\*\*

\- Lab 3.3: Policies for GCP (`google\_storage\_bucket`)

\- Lab 3.4: Policies for AWS (`aws\_s3\_bucket`)

\- \*\*Same Control IDs:\*\* SC-28, AC-3, CM-6



\## Policies



\### GCP Policies (from Lab 3.3)

\- `sc28\_encryption.rego` - google\_storage\_bucket CMEK requirement

\- `ac3\_no\_public.rego` - google\_storage\_bucket + google\_compute\_firewall access control

\- `cm6\_required\_tags.rego` - GCP labels requirement



\### AWS Policies (new in Lab 3.4)

\- `sc28\_encryption\_aws.rego` - aws\_s3\_bucket encryption configuration requirement

\- `ac3\_no\_public\_aws.rego` - aws\_s3\_bucket public access block requirement

\- `cm6\_required\_tags\_aws.rego` - AWS tags requirement



\## Policy Gate Script



`scripts/policy-gate.ps1` runs all policies and returns:

\- \*\*Exit 0:\*\* All policies pass (allows deployment)

\- \*\*Exit 1:\*\* Violations detected (blocks deployment)



\### Usage



\*\*Check compliant infrastructure:\*\*

```powershell

powershell -ExecutionPolicy Bypass -File scripts\\policy-gate.ps1 -Workspace "workspace"

```



\*\*Check broken infrastructure:\*\*

```powershell

powershell -ExecutionPolicy Bypass -File scripts\\policy-gate.ps1 -Workspace "broken"

```



\## Test Results



\### Compliant Plan (workspace/)

✅ SC-28 (Encryption): PASS

✅ AC-3 (Access Control): PASS

✅ CM-6 (Required Tags): PASS

Result: 0 failures, deployment allowed



\### Non-Compliant Plan (broken/)



❌ SC-28: 1 violation - missing encryption

❌ AC-3: 2 violations - missing public access blocks

❌ CM-6: 3 violations - missing required tags

Result: 6 failures, deployment blocked



\## Evidence Files



\- `evidence/conftest-pass.json` - Results from compliant infrastructure

\- `evidence/conftest-fail.json` - Results from broken infrastructure showing 6 violations



\## Real-World Impact



\*\*Traditional Approach:\*\*



Developer → Deploy → Auditor finds issues → Emergency fix

Time to detect: Weeks



\## Architecture

Terraform Code

↓

terraform plan -out=tfplan

↓

terraform show -json tfplan

↓

Conftest Test (per namespace)

↓

PASS → Exit 0 → Deploy ✅

FAIL → Exit 1 → Block ❌

\## CI/CD Integration



This script is designed to run in GitHub Actions (Lab 4.3):



```yaml

\- name: Policy Gate

&#x20; run: |

&#x20;   powershell -File scripts/policy-gate.ps1 -Workspace terraform/

&#x20; continue-on-error: false

```



If any policy fails, the pipeline stops.



\## Cross-Cloud Portability



\*\*The Lesson:\*\*

\- NIST Control IDs are portable across clouds

\- Resource type names are not

\- Solution: Cloud-specific policy variants with same control metadata



\*\*Example:\*\*



SC-28 on GCP: google\_storage\_bucket must have encryption block

SC-28 on AWS: aws\_s3\_bucket must have encryption configuration

Same Control: SC-28

Same Severity: High

Same Framework: NIST 800-53



\## How This Feeds the Capstone



`scripts/policy-gate.ps1` becomes the compliance gate in CI/CD pipelines (Lab 4.3). Every pull request runs this script. If violations are detected, the PR is blocked until fixed. This creates an automated "shift-left" compliance workflow where infrastructure cannot be deployed unless it passes all policy checks.





