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
  description = "Name prefix of the report plans. Hyphens are replaced by underscores and the lowercased template name is appended"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,200}$", var.name))
    error_message = "`name` must start with a letter and contain only letters, numbers, underscores or hyphens."
  }
}

variable "report_templates" {
  description = "Set of report templates to create a report plan for. Valid values: `BACKUP_JOB_REPORT`, `COPY_JOB_REPORT`, `RESTORE_JOB_REPORT`, `RESOURCE_COMPLIANCE_REPORT`, `CONTROL_COMPLIANCE_REPORT`"
  type        = set(string)
  default     = ["BACKUP_JOB_REPORT", "COPY_JOB_REPORT", "RESTORE_JOB_REPORT"]

  validation {
    condition     = alltrue([for template in var.report_templates : contains(["BACKUP_JOB_REPORT", "COPY_JOB_REPORT", "RESTORE_JOB_REPORT", "RESOURCE_COMPLIANCE_REPORT", "CONTROL_COMPLIANCE_REPORT"], template)])
    error_message = "`report_templates` contains an unsupported template."
  }

  validation {
    condition     = length(setintersection(var.report_templates, ["RESOURCE_COMPLIANCE_REPORT", "CONTROL_COMPLIANCE_REPORT"])) == 0 || length(var.framework_arns) > 0
    error_message = "`framework_arns` is required for the compliance report templates."
  }
}

variable "descriptions" {
  description = "Map of report plan descriptions keyed by template name"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket that receives the reports. The bucket policy must allow `AWSServiceRoleForBackupReports` to put objects"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.s3_bucket_name))
    error_message = "`s3_bucket_name` must be a valid S3 bucket name."
  }
}

variable "s3_key_prefix" {
  description = "Prefix under which the reports are delivered in the S3 bucket"
  type        = string
  default     = null
}

variable "formats" {
  description = "Set of report formats. Valid values: `CSV`, `JSON`"
  type        = set(string)
  default     = ["CSV", "JSON"]

  validation {
    condition     = length(var.formats) > 0 && alltrue([for format in var.formats : contains(["CSV", "JSON"], format)])
    error_message = "`formats` must contain `CSV` and/or `JSON`."
  }
}

variable "accounts" {
  description = "List of AWS account IDs covered by the reports. Defaults to the current account"
  type        = list(string)
  default     = null
}

variable "organization_units" {
  description = "List of AWS Organizations organizational unit IDs covered by the reports"
  type        = list(string)
  default     = null
}

variable "regions" {
  description = "List of AWS regions covered by the reports. Defaults to the current region"
  type        = list(string)
  default     = null
}

variable "framework_arns" {
  description = "List of AWS Backup Audit Manager framework ARNs covered by the compliance reports"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
