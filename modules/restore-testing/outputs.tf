output "plan_name" {
  description = "The name of the restore testing plan"
  value       = try(aws_backup_restore_testing_plan.this[0].name, null)
}

output "plan_arn" {
  description = "The ARN of the restore testing plan"
  value       = try(aws_backup_restore_testing_plan.this[0].arn, null)
}

output "selection_names" {
  description = "Map of restore testing selection names, keyed by selection key"
  value       = { for key, selection in aws_backup_restore_testing_selection.this : key => selection.name }
}
