output "id" {
  description = "The ID of the backup plan"
  value       = try(aws_backup_plan.this[0].id, null)
}

output "arn" {
  description = "The ARN of the backup plan"
  value       = try(aws_backup_plan.this[0].arn, null)
}

output "version" {
  description = "Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan"
  value       = try(aws_backup_plan.this[0].version, null)
}

output "selection_ids" {
  description = "Map of backup selection IDs, keyed by selection key"
  value       = { for key, selection in aws_backup_selection.this : key => selection.id }
}
