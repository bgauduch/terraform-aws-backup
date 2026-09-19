output "vault_arn" {
  description = "The ARN of the backup vault"
  value       = module.backup.vault_arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role used by backup selections and restore tests"
  value       = module.backup.iam_role_arn
}

output "restore_testing_plan_name" {
  description = "The name of the restore testing plan"
  value       = module.restore_testing.plan_name
}

output "restore_testing_plan_arn" {
  description = "The ARN of the restore testing plan"
  value       = module.restore_testing.plan_arn
}

output "restore_testing_selection_names" {
  description = "Map of restore testing selection names"
  value       = module.restore_testing.selection_names
}
