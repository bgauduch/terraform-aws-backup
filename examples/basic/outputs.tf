output "vault_arn" {
  description = "The ARN of the backup vault"
  value       = module.backup.vault_arn
}

output "vault_name" {
  description = "The name of the backup vault"
  value       = module.backup.vault_name
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
