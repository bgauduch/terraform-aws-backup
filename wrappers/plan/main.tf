module "wrapper" {
  source = "../../modules/plan"

  for_each = var.items

  create              = try(each.value.create, var.defaults.create, true)
  iam_role_arn        = try(each.value.iam_role_arn, var.defaults.iam_role_arn)
  name                = try(each.value.name, var.defaults.name)
  region              = try(each.value.region, var.defaults.region, null)
  rules               = try(each.value.rules, var.defaults.rules)
  selections          = try(each.value.selections, var.defaults.selections, {})
  tags                = try(each.value.tags, var.defaults.tags, {})
  vault_name          = try(each.value.vault_name, var.defaults.vault_name)
  windows_vss_enabled = try(each.value.windows_vss_enabled, var.defaults.windows_vss_enabled, false)
}
