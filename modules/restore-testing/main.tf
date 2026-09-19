locals {
  plan_name = replace(var.name, "-", "_")
}

################################################################################
# Restore testing plan
################################################################################

resource "aws_backup_restore_testing_plan" "this" {
  count = var.create ? 1 : 0

  region = var.region

  name                         = local.plan_name
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone
  start_window_hours           = var.start_window_hours

  recovery_point_selection {
    algorithm             = var.recovery_point_selection_algorithm
    include_vaults        = var.include_vaults
    exclude_vaults        = var.exclude_vaults
    recovery_point_types  = var.recovery_point_types
    selection_window_days = var.selection_window_days
  }

  tags = var.tags
}

################################################################################
# Restore testing selections, one per protected resource type
################################################################################

resource "aws_backup_restore_testing_selection" "this" {
  for_each = var.create ? var.selections : {}

  region = var.region

  name                      = coalesce(each.value.name, replace(each.key, "-", "_"))
  restore_testing_plan_name = aws_backup_restore_testing_plan.this[0].name
  protected_resource_type   = each.value.protected_resource_type
  iam_role_arn              = coalesce(each.value.iam_role_arn, var.iam_role_arn)

  protected_resource_arns    = each.value.protected_resource_arns
  restore_metadata_overrides = each.value.restore_metadata_overrides
  validation_window_hours    = each.value.validation_window_hours

  dynamic "protected_resource_conditions" {
    for_each = each.value.protected_resource_conditions != null ? [each.value.protected_resource_conditions] : []

    content {
      dynamic "string_equals" {
        for_each = protected_resource_conditions.value.string_equals

        content {
          key   = string_equals.value.key
          value = string_equals.value.value
        }
      }

      dynamic "string_not_equals" {
        for_each = protected_resource_conditions.value.string_not_equals

        content {
          key   = string_not_equals.value.key
          value = string_not_equals.value.value
        }
      }
    }
  }
}
