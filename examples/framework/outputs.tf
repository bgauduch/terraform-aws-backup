output "vault_arn" {
  description = "The ARN of the backup vault"
  value       = module.backup.vault_arn
}

output "framework_arn" {
  description = "The ARN of the framework"
  value       = module.framework.arn
}

output "framework_id" {
  description = "The name of the framework"
  value       = module.framework.id
}

output "framework_deployment_status" {
  description = "The deployment status of the framework"
  value       = module.framework.deployment_status
}

output "config_recorder_name" {
  description = "The name of the AWS Config recorder created by the example, if any"
  value       = try(aws_config_configuration_recorder.this[0].name, null)
}
