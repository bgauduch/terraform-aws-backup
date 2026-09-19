################################################################################
# Vault
################################################################################

output "vault_id" {
  description = "The name of the backup vault"
  value       = try(aws_backup_vault.this[0].id, null)
}

output "vault_arn" {
  description = "The ARN of the backup vault"
  value       = try(aws_backup_vault.this[0].arn, null)
}

output "vault_name" {
  description = "The name of the vault targeted by the backup plans, created or provided"
  value       = local.target_vault_name
}

output "vault_recovery_points" {
  description = "The number of recovery points stored in the backup vault"
  value       = try(aws_backup_vault.this[0].recovery_points, null)
}

output "vault_lock_configuration_id" {
  description = "The name of the vault the lock configuration applies to"
  value       = try(aws_backup_vault_lock_configuration.this[0].id, null)
}

################################################################################
# Logically air-gapped vault
################################################################################

output "air_gapped_vault_id" {
  description = "The name of the logically air-gapped vault"
  value       = try(aws_backup_logically_air_gapped_vault.this[0].id, null)
}

output "air_gapped_vault_arn" {
  description = "The ARN of the logically air-gapped vault"
  value       = try(aws_backup_logically_air_gapped_vault.this[0].arn, null)
}

################################################################################
# IAM role
################################################################################

output "iam_role_arn" {
  description = "The ARN of the IAM role used by backup selections, created or provided"
  value       = local.iam_role_arn
}

output "iam_role_name" {
  description = "The name of the IAM role created by the module"
  value       = try(aws_iam_role.this[0].name, null)
}

################################################################################
# Plans
################################################################################

output "plans" {
  description = "Map of backup plans created, keyed by plan key, with `id`, `arn` and `version`"
  value = {
    for key, plan in module.plan : key => {
      id      = plan.id
      arn     = plan.arn
      version = plan.version
    }
  }
}

output "selections" {
  description = "Map of backup selection IDs, keyed by `<plan key>/<selection key>`"
  value = merge([
    for key, plan in module.plan : {
      for selection_key, id in plan.selection_ids : "${key}/${selection_key}" => id
    }
  ]...)
}
