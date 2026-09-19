output "id" {
  description = "The name of the framework"
  value       = try(aws_backup_framework.this[0].id, null)
}

output "arn" {
  description = "The ARN of the framework"
  value       = try(aws_backup_framework.this[0].arn, null)
}

output "status" {
  description = "The framework consistency status: `ACTIVE`, `PARTIALLY_ACTIVE`, `INACTIVE` or `UNAVAILABLE`"
  value       = try(aws_backup_framework.this[0].status, null)
}

output "deployment_status" {
  description = "The deployment status of the framework: `CREATE_IN_PROGRESS`, `UPDATE_IN_PROGRESS`, `DELETE_IN_PROGRESS`, `COMPLETED` or `FAILED`"
  value       = try(aws_backup_framework.this[0].deployment_status, null)
}
