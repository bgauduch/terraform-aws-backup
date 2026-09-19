module "wrapper" {
  source = "../../modules/restore-testing"

  for_each = var.items

  create                             = try(each.value.create, var.defaults.create, true)
  exclude_vaults                     = try(each.value.exclude_vaults, var.defaults.exclude_vaults, null)
  iam_role_arn                       = try(each.value.iam_role_arn, var.defaults.iam_role_arn, null)
  include_vaults                     = try(each.value.include_vaults, var.defaults.include_vaults)
  name                               = try(each.value.name, var.defaults.name)
  recovery_point_selection_algorithm = try(each.value.recovery_point_selection_algorithm, var.defaults.recovery_point_selection_algorithm, "LATEST_WITHIN_WINDOW")
  recovery_point_types               = try(each.value.recovery_point_types, var.defaults.recovery_point_types, ["SNAPSHOT"])
  region                             = try(each.value.region, var.defaults.region, null)
  schedule_expression                = try(each.value.schedule_expression, var.defaults.schedule_expression)
  schedule_expression_timezone       = try(each.value.schedule_expression_timezone, var.defaults.schedule_expression_timezone, null)
  selection_window_days              = try(each.value.selection_window_days, var.defaults.selection_window_days, 7)
  selections                         = try(each.value.selections, var.defaults.selections, {})
  start_window_hours                 = try(each.value.start_window_hours, var.defaults.start_window_hours, null)
  tags                               = try(each.value.tags, var.defaults.tags, {})
}
