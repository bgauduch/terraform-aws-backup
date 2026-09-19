output "plan_id" {
  description = "The ID of the backup plan"
  value       = module.plan.id
}

output "plan_arn" {
  description = "The ARN of the backup plan"
  value       = module.plan.arn
}

output "selection_ids" {
  description = "Map of backup selection IDs"
  value       = module.plan.selection_ids
}

output "vault_name" {
  description = "The name of the existing vault targeted by the plan"
  value       = aws_backup_vault.existing.name
}
