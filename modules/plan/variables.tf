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
  description = "Name of the backup plan"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{1,50}$", var.name))
    error_message = "`name` must be 1 to 50 alphanumeric characters, hyphens, underscores or periods."
  }
}

variable "vault_name" {
  description = "Name of the backup vault targeted by the rules"
  type        = string
}

variable "iam_role_arn" {
  description = "ARN of the IAM role assumed by AWS Backup for the selections"
  type        = string

  validation {
    condition     = can(regex("^arn:[a-z-]+:iam::[0-9]{12}:role/.+$", var.iam_role_arn))
    error_message = "`iam_role_arn` must be an IAM role ARN."
  }
}

variable "windows_vss_enabled" {
  description = "Determines whether Windows VSS backup is enabled for EC2 instances"
  type        = bool
  default     = false
}

variable "rules" {
  description = "List of backup rules: `name`, `schedule` (cron), `schedule_expression_timezone`, `start_window`, `completion_window`, `enable_continuous_backup`, `recovery_point_tags`, `target_logically_air_gapped_backup_vault_arn`, `lifecycle` (`cold_storage_after`, `delete_after`, `opt_in_to_archive_for_supported_resources`), `copy_actions[]` (`destination_vault_arn`, `lifecycle`)"
  type = list(object({
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
  }))

  validation {
    condition     = length(var.rules) > 0
    error_message = "At least one rule is required."
  }

  validation {
    condition     = alltrue([for rule in var.rules : rule.lifecycle == null || try(rule.lifecycle.cold_storage_after == null || rule.lifecycle.delete_after == null || rule.lifecycle.delete_after >= rule.lifecycle.cold_storage_after + 90, true)])
    error_message = "`lifecycle.delete_after` must be at least 90 days greater than `lifecycle.cold_storage_after`."
  }

  validation {
    condition     = alltrue([for rule in var.rules : !coalesce(rule.enable_continuous_backup, false) || coalesce(try(rule.lifecycle.delete_after, null), 35) <= 35])
    error_message = "`lifecycle.delete_after` cannot exceed 35 days when `enable_continuous_backup` is `true`."
  }

  validation {
    condition = alltrue(flatten([
      for rule in var.rules : [
        for copy_action in rule.copy_actions : copy_action.lifecycle == null || try(copy_action.lifecycle.cold_storage_after == null || copy_action.lifecycle.delete_after == null || copy_action.lifecycle.delete_after >= copy_action.lifecycle.cold_storage_after + 90, true)
      ]
    ]))
    error_message = "`copy_actions[].lifecycle.delete_after` must be at least 90 days greater than `cold_storage_after`."
  }
}

variable "selections" {
  description = "Map of resource selections keyed by selection name: `name`, `resources`, `not_resources`, `selection_tags[]` (`type`, `key`, `value`), `conditions` (`string_equals[]`, `string_like[]`, `string_not_equals[]`, `string_not_like[]` of `key`/`value`)"
  type = map(object({
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
  }))
  default = {}

  validation {
    condition     = alltrue([for selection in var.selections : alltrue([for tag in selection.selection_tags : contains(["STRINGEQUALS"], tag.type)])])
    error_message = "`selection_tags[].type` must be `STRINGEQUALS`."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
