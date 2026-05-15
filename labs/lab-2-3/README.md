# Compliant S3 Bucket - Lab 2.3

This Terraform module creates an AWS S3 bucket that satisfies five NIST 800-53 controls:

- **SC-28**: Protection of Information at Rest (AES-256 encryption)
- **AU-3**: Content of Audit Records (S3 access logging enabled)
- **AU-6**: Audit Review (logs stored in separate bucket)
- **CM-6**: Configuration Settings (versioning + compliance tags)
- **AC-3**: Access Enforcement (all public access blocked)

## Resources Created
- Primary S3 bucket with encryption, versioning, and public access block
- Logging S3 bucket to store access logs
- Automatic compliance tags on all resources

## Evidence
See `evidence/state.json` for machine-readable compliance proof.