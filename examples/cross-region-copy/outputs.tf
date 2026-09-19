output "vault_arn" {
  description = "The ARN of the primary backup vault"
  value       = module.backup.vault_arn
}

output "vault_name" {
  description = "The name of the primary backup vault"
  value       = module.backup.vault_name
}

output "secondary_vault_arn" {
  description = "The ARN of the secondary backup vault receiving the copies"
  value       = module.backup_secondary.vault_arn
}

output "secondary_vault_name" {
  description = "The name of the secondary backup vault receiving the copies"
  value       = module.backup_secondary.vault_name
}

output "iam_role_arn" {
  description = "The ARN of the IAM role used by backup selections"
  value       = module.backup.iam_role_arn
}

output "plans" {
  description = "Map of backup plans created"
  value       = module.backup.plans
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table protected by the backup plan"
  value       = aws_dynamodb_table.this.arn
}
