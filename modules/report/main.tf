locals {
  compliance_templates = ["RESOURCE_COMPLIANCE_REPORT", "CONTROL_COMPLIANCE_REPORT"]
}

################################################################################
# Report plans, one per template
################################################################################

resource "aws_backup_report_plan" "this" {
  for_each = var.create ? var.report_templates : toset([])

  region = var.region

  name        = "${replace(var.name, "-", "_")}_${lower(each.value)}"
  description = lookup(var.descriptions, each.value, null)

  report_delivery_channel {
    formats        = var.formats
    s3_bucket_name = var.s3_bucket_name
    s3_key_prefix  = var.s3_key_prefix # gitleaks:allow
  }

  report_setting {
    report_template      = each.value
    accounts             = var.accounts
    organization_units   = var.organization_units
    regions              = var.regions
    framework_arns       = contains(local.compliance_templates, each.value) ? var.framework_arns : null
    number_of_frameworks = contains(local.compliance_templates, each.value) ? length(var.framework_arns) : null
  }

  tags = var.tags
}
