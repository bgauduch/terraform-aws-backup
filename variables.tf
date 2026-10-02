variable "create" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}

variable "region" {
  description = "Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration"
  type        = string
  default     = null
}

variable "name" {
  description = "Name used as the default for the vault, the IAM role and the air-gapped vault"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,50}$", var.name))
    error_message = "`name` must be 1 to 50 alphanumeric characters, hyphens or underscores."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "putin_khuylo" {
  description = "Do you agree that Putin doesn't respect Ukrainian sovereignty and territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo!"
  type        = bool
  default     = true
}

################################################################################
# Vault
################################################################################

variable "create_vault" {
  description = "Determines whether a backup vault is created. Set to `false` to target an existing vault through `existing_vault_name`"
  type        = bool
  default     = true
}

variable "existing_vault_name" {
  description = "Name of an existing backup vault targeted by the plans and notifications when `create_vault` is `false`"
  type        = string
  default     = null
}

variable "vault_name" {
  description = "Name of the backup vault. Defaults to `name`"
  type        = string
  default     = null

  validation {
    condition     = var.vault_name == null || can(regex("^[a-zA-Z0-9_-]{2,50}$", var.vault_name))
    error_message = "`vault_name` must be 2 to 50 alphanumeric characters, hyphens or underscores."
  }
}

variable "vault_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the backup vault. Defaults to the AWS managed key `aws/backup`. The key policy must allow AWS Backup to use the key"
  type        = string
  default     = null
}

variable "vault_force_destroy" {
  description = "Determines whether all recovery points stored in the vault are deleted so that the vault can be destroyed without error"
  type        = bool
  default     = false
}

variable "attach_vault_policy" {
  description = "Determines whether `vault_policy` is attached to the backup vault. The statements generated from `vault_copy_source_account_ids` are attached regardless"
  type        = bool
  default     = false
}

variable "vault_policy" {
  description = "IAM policy document (JSON) applied to the backup vault when `attach_vault_policy` is `true`. Merged with the statements generated from `vault_copy_source_account_ids`"
  type        = string
  default     = null

  validation {
    condition     = var.vault_policy == null || can(jsondecode(var.vault_policy))
    error_message = "`vault_policy` must be a valid JSON document."
  }
}

variable "vault_copy_source_account_ids" {
  description = "List of AWS account IDs allowed to copy recovery points into the backup vault (cross-account backup)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.vault_copy_source_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "`vault_copy_source_account_ids` must contain 12-digit AWS account IDs."
  }
}

################################################################################
# Vault lock
################################################################################

variable "vault_lock_enabled" {
  description = "Determines whether a vault lock configuration is created on the backup vault"
  type        = bool
  default     = false
}

variable "vault_lock_min_retention_days" {
  description = "The minimum retention period, in days, that the vault retains its recovery points"
  type        = number
  default     = null

  validation {
    condition     = var.vault_lock_min_retention_days == null || try(var.vault_lock_min_retention_days >= 1 && var.vault_lock_min_retention_days <= 36500, false)
    error_message = "`vault_lock_min_retention_days` must be between 1 and 36500."
  }
}

variable "vault_lock_max_retention_days" {
  description = "The maximum retention period, in days, that the vault retains its recovery points"
  type        = number
  default     = null

  validation {
    condition     = var.vault_lock_max_retention_days == null || try(var.vault_lock_max_retention_days >= 1 && var.vault_lock_max_retention_days <= 36500, false)
    error_message = "`vault_lock_max_retention_days` must be between 1 and 36500."
  }
}

variable "vault_lock_changeable_for_days" {
  description = "The number of days before the lock date. When set, the vault lock is created in compliance mode and cannot be removed once the lock date is reached. Leave `null` for governance mode"
  type        = number
  default     = null

  validation {
    condition     = var.vault_lock_changeable_for_days == null || try(var.vault_lock_changeable_for_days >= 3 && var.vault_lock_changeable_for_days <= 36500, false)
    error_message = "`vault_lock_changeable_for_days` must be between 3 and 36500."
  }
}

################################################################################
# Vault notifications
################################################################################

variable "vault_notifications_enabled" {
  description = "Determines whether the backup vault events are sent to `vault_notifications_sns_topic_arn`"
  type        = bool
  default     = false
}

variable "vault_notifications_sns_topic_arn" {
  description = "ARN of the SNS topic that receives the backup vault events when `vault_notifications_enabled` is `true`. The topic policy must allow `backup.amazonaws.com` to publish"
  type        = string
  default     = null
}

variable "vault_notifications_events" {
  description = "List of backup vault events sent to the SNS topic"
  type        = list(string)
  default     = ["BACKUP_JOB_FAILED", "COPY_JOB_FAILED", "RESTORE_JOB_FAILED"]

  validation {
    condition = alltrue([for event in var.vault_notifications_events : contains([
      "BACKUP_JOB_STARTED", "BACKUP_JOB_COMPLETED", "BACKUP_JOB_SUCCESSFUL", "BACKUP_JOB_FAILED", "BACKUP_JOB_EXPIRED",
      "COPY_JOB_STARTED", "COPY_JOB_SUCCESSFUL", "COPY_JOB_FAILED",
      "RESTORE_JOB_STARTED", "RESTORE_JOB_COMPLETED", "RESTORE_JOB_SUCCESSFUL", "RESTORE_JOB_FAILED",
      "RECOVERY_POINT_MODIFIED", "BACKUP_PLAN_CREATED", "BACKUP_PLAN_MODIFIED", "S3_BACKUP_OBJECT_FAILED", "S3_RESTORE_OBJECT_FAILED",
    ], event)])
    error_message = "`vault_notifications_events` contains an unsupported backup vault event."
  }
}

################################################################################
# Logically air-gapped vault
################################################################################

variable "air_gapped_vault_enabled" {
  description = "Determines whether a logically air-gapped vault is created"
  type        = bool
  default     = false
}

variable "air_gapped_vault_name" {
  description = "Name of the logically air-gapped vault. Defaults to `<name>-air-gapped`"
  type        = string
  default     = null

  validation {
    condition     = var.air_gapped_vault_name == null || can(regex("^[a-zA-Z0-9_-]{2,50}$", var.air_gapped_vault_name))
    error_message = "`air_gapped_vault_name` must be 2 to 50 alphanumeric characters, hyphens or underscores."
  }
}

variable "air_gapped_vault_min_retention_days" {
  description = "The minimum retention period, in days, that the logically air-gapped vault retains its recovery points"
  type        = number
  default     = 7

  validation {
    condition     = var.air_gapped_vault_min_retention_days >= 7 && var.air_gapped_vault_min_retention_days <= 36500
    error_message = "`air_gapped_vault_min_retention_days` must be between 7 and 36500."
  }
}

variable "air_gapped_vault_max_retention_days" {
  description = "The maximum retention period, in days, that the logically air-gapped vault retains its recovery points"
  type        = number
  default     = 35

  validation {
    condition     = var.air_gapped_vault_max_retention_days >= 7 && var.air_gapped_vault_max_retention_days <= 36500
    error_message = "`air_gapped_vault_max_retention_days` must be between 7 and 36500."
  }
}

variable "air_gapped_vault_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the logically air-gapped vault. Defaults to the AWS managed key"
  type        = string
  default     = null
}

################################################################################
# IAM role
################################################################################

variable "create_iam_role" {
  description = "Determines whether the IAM role assumed by AWS Backup is created. Set to `false` to use `iam_role_arn`"
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "ARN of an existing IAM role assumed by AWS Backup for the selections when `create_iam_role` is `false`. Can be overridden per plan"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name of the IAM role. Defaults to `<name>-backup`"
  type        = string
  default     = null
}

variable "iam_role_path" {
  description = "Path of the IAM role"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy used as the permissions boundary of the IAM role"
  type        = string
  default     = null
}

variable "iam_role_max_session_duration" {
  description = "Maximum session duration, in seconds, of the IAM role"
  type        = number
  default     = null
}

variable "iam_role_force_detach_policies" {
  description = "Determines whether policies attached to the IAM role are detached before the role is destroyed"
  type        = bool
  default     = true
}

variable "iam_role_attach_s3_policies" {
  description = "Determines whether the AWS managed policies for S3 backup and restore are attached to the IAM role"
  type        = bool
  default     = true
}

variable "iam_role_additional_policy_arns" {
  description = "List of additional IAM policy ARNs attached to the IAM role, for example `AWSBackupServiceRolePolicyForItemRestores`"
  type        = list(string)
  default     = []
}

variable "attach_iam_role_additional_policy" {
  description = "Determines whether `iam_role_additional_policy_json` is attached inline to the IAM role"
  type        = bool
  default     = false
}

variable "iam_role_additional_policy_name" {
  description = "Name of the inline policy attached to the IAM role when `attach_iam_role_additional_policy` is `true`"
  type        = string
  default     = "additional"
}

variable "iam_role_additional_policy_json" {
  description = "IAM policy document (JSON) attached inline to the IAM role when `attach_iam_role_additional_policy` is `true`, for example KMS permissions on the keys of the protected resources"
  type        = string
  default     = null

  validation {
    condition     = var.iam_role_additional_policy_json == null || can(jsondecode(var.iam_role_additional_policy_json))
    error_message = "`iam_role_additional_policy_json` must be a valid JSON document."
  }
}

################################################################################
# Plans
################################################################################

variable "plans" {
  description = <<-EOT
  Map of backup plans to create, keyed by plan name. Each plan has one or more `rules` and zero or more `selections`:
  - `name`: plan name, defaults to the map key
  - `windows_vss_enabled`: enable Windows VSS backup for EC2 instances
  - `iam_role_arn`: IAM role assumed by AWS Backup for the selections of this plan, defaults to the module role
  - `scan_settings[]`: `malware_scanner`, `resource_types`, `scanner_role_arn`
  - `rules[]`: `name`, `schedule` (cron), `schedule_expression_timezone`, `start_window`, `completion_window`, `enable_continuous_backup`, `recovery_point_tags`, `target_logically_air_gapped_backup_vault_arn`, `lifecycle` (`cold_storage_after`, `delete_after`, `opt_in_to_archive_for_supported_resources`), `copy_actions[]` (`destination_vault_arn`, `lifecycle`), `scan_actions[]` (`malware_scanner`, `scan_mode`)
  - `selections{}`: keyed by selection name: `name`, `resources`, `not_resources`, `selection_tags[]` (`type`, `key`, `value`), `conditions` (`string_equals[]`, `string_like[]`, `string_not_equals[]`, `string_not_like[]` of `key`/`value`)
  EOT
  type = map(object({
    name                = optional(string)
    windows_vss_enabled = optional(bool, false)
    iam_role_arn        = optional(string)
    scan_settings = optional(list(object({
      malware_scanner  = string
      resource_types   = list(string)
      scanner_role_arn = string
    })), [])
    rules = list(object({
      name                                         = string
      schedule                                     = optional(string)
      schedule_expression_timezone                 = optional(string)
      start_window                                 = optional(number)
      completion_window                            = optional(number)
      enable_continuous_backup                     = optional(bool)
      recovery_point_tags                          = optional(map(string))
      target_logically_air_gapped_backup_vault_arn = optional(string)
      lifecycle = optional(object({
        cold_storage_after                        = optional(number)
        delete_after                              = optional(number)
        opt_in_to_archive_for_supported_resources = optional(bool)
      }))
      copy_actions = optional(list(object({
        destination_vault_arn = string
        lifecycle = optional(object({
          cold_storage_after                        = optional(number)
          delete_after                              = optional(number)
          opt_in_to_archive_for_supported_resources = optional(bool)
        }))
      })), [])
      scan_actions = optional(list(object({
        malware_scanner = string
        scan_mode       = string
      })), [])
    }))
    selections = optional(map(object({
      name          = optional(string)
      resources     = optional(list(string))
      not_resources = optional(list(string))
      selection_tags = optional(list(object({
        type  = string
        key   = string
        value = string
      })), [])
      conditions = optional(object({
        string_equals     = optional(list(object({ key = string, value = string })), [])
        string_like       = optional(list(object({ key = string, value = string })), [])
        string_not_equals = optional(list(object({ key = string, value = string })), [])
        string_not_like   = optional(list(object({ key = string, value = string })), [])
      }))
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for plan in var.plans : length(plan.rules) > 0])
    error_message = "Each plan must define at least one rule."
  }

  validation {
    condition = alltrue(flatten([
      for plan in var.plans : [
        for rule in plan.rules : rule.lifecycle == null || try(rule.lifecycle.cold_storage_after == null || rule.lifecycle.delete_after == null || rule.lifecycle.delete_after >= rule.lifecycle.cold_storage_after + 90, true)
      ]
    ]))
    error_message = "`lifecycle.delete_after` must be at least 90 days greater than `lifecycle.cold_storage_after`."
  }

  validation {
    condition = alltrue(flatten([
      for plan in var.plans : [
        for rule in plan.rules : !coalesce(rule.enable_continuous_backup, false) || coalesce(try(rule.lifecycle.delete_after, null), 35) <= 35
      ]
    ]))
    error_message = "`lifecycle.delete_after` cannot exceed 35 days when `enable_continuous_backup` is `true`."
  }

  validation {
    condition = alltrue(flatten([
      for plan in var.plans : [
        for rule in plan.rules : [
          for copy_action in rule.copy_actions : copy_action.lifecycle == null || try(copy_action.lifecycle.cold_storage_after == null || copy_action.lifecycle.delete_after == null || copy_action.lifecycle.delete_after >= copy_action.lifecycle.cold_storage_after + 90, true)
        ]
      ]
    ]))
    error_message = "`copy_actions[].lifecycle.delete_after` must be at least 90 days greater than `cold_storage_after`."
  }
}
