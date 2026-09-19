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
  description = "Name of the framework. Hyphens are replaced by underscores"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,255}$", var.name))
    error_message = "`name` must start with a letter and contain only letters, numbers, underscores or hyphens."
  }
}

variable "description" {
  description = "Description of the framework"
  type        = string
  default     = null
}

variable "controls" {
  description = "Map of controls keyed by AWS Backup Audit Manager control name. Each control has optional `input_parameters` (map of parameter name to value) and an optional `scope` (`compliance_resource_ids`, `compliance_resource_types`, `tags` with a single entry)"
  type = map(object({
    input_parameters = optional(map(string), {})
    scope = optional(object({
      compliance_resource_ids   = optional(list(string))
      compliance_resource_types = optional(list(string))
      tags                      = optional(map(string))
    }))
  }))

  validation {
    condition     = length(var.controls) > 0
    error_message = "At least one control is required."
  }

  validation {
    condition = alltrue([for name in keys(var.controls) : contains([
      "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN",
      "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK",
      "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK",
      "BACKUP_RECOVERY_POINT_ENCRYPTED",
      "BACKUP_RECOVERY_POINT_MANUAL_DELETION_DISABLED",
      "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_VAULT_LOCK",
      "BACKUP_LAST_RECOVERY_POINT_CREATED",
      "RESTORE_TIME_FOR_RESOURCES_MEET_TARGET",
      "BACKUP_RESOURCES_PROTECTED_BY_CROSS_REGION",
      "BACKUP_RESOURCES_PROTECTED_BY_CROSS_ACCOUNT",
    ], name)])
    error_message = "`controls` contains an unsupported control name."
  }

  validation {
    condition     = alltrue([for control in var.controls : control.scope == null || try(length(control.scope.tags), 0) <= 1])
    error_message = "`controls[].scope.tags` accepts a single tag."
  }
}

variable "timeouts" {
  description = "Create, update, and delete timeout configurations for the framework. AWS Backup deploys the underlying AWS Config rules asynchronously"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
