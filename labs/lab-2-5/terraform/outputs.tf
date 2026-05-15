# outputs.tf
output "vault_name" {
  value       = aws_s3_bucket.vault.id
  description = "Name of your evidence vault"
}