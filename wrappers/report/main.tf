module "wrapper" {
  source = "../../modules/report"

  for_each = var.items

  accounts           = try(each.value.accounts, var.defaults.accounts, null)
  create             = try(each.value.create, var.defaults.create, true)
  descriptions       = try(each.value.descriptions, var.defaults.descriptions, {})
  formats            = try(each.value.formats, var.defaults.formats, ["CSV", "JSON"])
  framework_arns     = try(each.value.framework_arns, var.defaults.framework_arns, [])
  name               = try(each.value.name, var.defaults.name)
  organization_units = try(each.value.organization_units, var.defaults.organization_units, null)
  region             = try(each.value.region, var.defaults.region, null)
  regions            = try(each.value.regions, var.defaults.regions, null)
  report_templates   = try(each.value.report_templates, var.defaults.report_templates, ["BACKUP_JOB_REPORT", "COPY_JOB_REPORT", "RESTORE_JOB_REPORT"])
  s3_bucket_name     = try(each.value.s3_bucket_name, var.defaults.s3_bucket_name)
  s3_key_prefix      = try(each.value.s3_key_prefix, var.defaults.s3_key_prefix, null)
  tags               = try(each.value.tags, var.defaults.tags, {})
}
