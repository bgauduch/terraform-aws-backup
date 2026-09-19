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
  description = "Name of the restore testing plan. Hyphens are replaced by underscores"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,50}$", var.name))
    error_message = "`name` must be 1 to 50 alphanumeric characters, hyphens or underscores."
  }
}

variable "schedule_expression" {
  description = "Cron expression that defines when the restore tests run"
  type        = string
}

variable "schedule_expression_timezone" {
  description = "Timezone of the schedule expression"
  type        = string
  default     = null
}

variable "start_window_hours" {
  description = "Number of hours during which the restore tests can start, between 1 and 168"
  type        = number
  default     = null

  validation {
    condition     = var.start_window_hours == null || try(var.start_window_hours >= 1 && var.start_window_hours <= 168, false)
    error_message = "`start_window_hours` must be between 1 and 168."
  }
}

variable "recovery_point_selection_algorithm" {
  description = "Algorithm used to select the recovery points. Valid values: `LATEST_WITHIN_WINDOW`, `RANDOM_WITHIN_WINDOW`"
  type        = string
  default     = "LATEST_WITHIN_WINDOW"

  validation {
    condition     = contains(["LATEST_WITHIN_WINDOW", "RANDOM_WITHIN_WINDOW"], var.recovery_point_selection_algorithm)
    error_message = "`recovery_point_selection_algorithm` must be `LATEST_WITHIN_WINDOW` or `RANDOM_WITHIN_WINDOW`."
  }
}

variable "include_vaults" {
  description = "List of backup vault ARNs the recovery points are selected from, or `[\"*\"]` for all vaults"
  type        = list(string)
}

variable "exclude_vaults" {
  description = "List of backup vault ARNs excluded from the recovery point selection"
  type        = list(string)
  default     = null
}

variable "recovery_point_types" {
  description = "List of recovery point types selected. Valid values: `SNAPSHOT`, `CONTINUOUS`"
  type        = list(string)
  default     = ["SNAPSHOT"]

  validation {
    condition     = length(var.recovery_point_types) > 0 && alltrue([for type in var.recovery_point_types : contains(["SNAPSHOT", "CONTINUOUS"], type)])
    error_message = "`recovery_point_types` must contain `SNAPSHOT` and/or `CONTINUOUS`."
  }
}

variable "selection_window_days" {
  description = "Number of days, between 1 and 365, within which the recovery points are selected"
  type        = number
  default     = 7

  validation {
    condition     = var.selection_window_days >= 1 && var.selection_window_days <= 365
    error_message = "`selection_window_days` must be between 1 and 365."
  }
}

variable "iam_role_arn" {
  description = "ARN of the IAM role assumed by AWS Backup for the restore tests. It must carry the restore permissions of the protected resource types. Can be overridden per selection"
  type        = string
  default     = null

  validation {
    condition     = var.iam_role_arn == null || can(regex("^arn:[a-z-]+:iam::[0-9]{12}:role/.+$", var.iam_role_arn))
    error_message = "`iam_role_arn` must be an IAM role ARN."
  }
}

variable "selections" {
  description = "Map of restore testing selections keyed by selection name, one per protected resource type: `name`, `protected_resource_type`, `iam_role_arn`, exactly one of `protected_resource_arns` or `protected_resource_conditions` (`string_equals[]`, `string_not_equals[]` of `key`/`value`, keys prefixed by `aws:ResourceTag/`), `restore_metadata_overrides`, `validation_window_hours`"
  type = map(object({
    name                    = optional(string)
    protected_resource_type = string
    iam_role_arn            = optional(string)
    protected_resource_arns = optional(list(string))
    protected_resource_conditions = optional(object({
      string_equals     = optional(list(object({ key = string, value = string })), [])
      string_not_equals = optional(list(object({ key = string, value = string })), [])
    }))
    restore_metadata_overrides = optional(map(string))
    validation_window_hours    = optional(number)
  }))
  default = {}

  validation {
    condition     = alltrue([for selection in var.selections : (selection.protected_resource_arns != null) != (selection.protected_resource_conditions != null)])
    error_message = "Each selection must define exactly one of `protected_resource_arns` or `protected_resource_conditions`."
  }

  validation {
    condition     = alltrue([for selection in var.selections : selection.validation_window_hours == null || try(selection.validation_window_hours >= 1 && selection.validation_window_hours <= 168, false)])
    error_message = "`validation_window_hours` must be between 1 and 168."
  }

  validation {
    condition     = var.iam_role_arn != null || alltrue([for selection in var.selections : selection.iam_role_arn != null])
    error_message = "`iam_role_arn` is required at module level or on each selection."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
