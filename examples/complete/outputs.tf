output "vault_arn" {
  description = "The ARN of the backup vault"
  value       = module.backup.vault_arn
}

output "vault_name" {
  description = "The name of the backup vault"
  value       = module.backup.vault_name
}

output "vault_lock_configuration_id" {
  description = "The name of the vault the lock configuration applies to"
  value       = module.backup.vault_lock_configuration_id
}

output "air_gapped_vault_arn" {
  description = "The ARN of the logically air-gapped vault"
  value       = module.backup.air_gapped_vault_arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role used by backup selections"
  value       = module.backup.iam_role_arn
}

output "plans" {
  description = "Map of backup plans created"
  value       = module.backup.plans
}

output "selections" {
  description = "Map of backup selection IDs"
  value       = module.backup.selections
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table protected by the backup plan"
  value       = aws_dynamodb_table.this.arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table protected by the backup plan"
  value       = aws_dynamodb_table.this.name
}

output "kms_key_arn" {
  description = "The ARN of the KMS key encrypting the vault"
  value       = aws_kms_key.vault.arn
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic receiving the vault notifications"
  value       = aws_sns_topic.backup.arn
}
