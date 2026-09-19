################################################################################
# Plan
################################################################################

resource "aws_backup_plan" "this" {
  count = var.create ? 1 : 0

  region = var.region

  name = var.name

  dynamic "rule" {
    for_each = var.rules

    content {
      rule_name                                    = rule.value.name
      target_vault_name                            = var.vault_name
      schedule                                     = rule.value.schedule
      schedule_expression_timezone                 = rule.value.schedule_expression_timezone
      start_window                                 = rule.value.start_window
      completion_window                            = rule.value.completion_window
      enable_continuous_backup                     = rule.value.enable_continuous_backup
      recovery_point_tags                          = rule.value.recovery_point_tags
      target_logically_air_gapped_backup_vault_arn = rule.value.target_logically_air_gapped_backup_vault_arn

      dynamic "lifecycle" {
        for_each = rule.value.lifecycle != null ? [rule.value.lifecycle] : []

        content {
          cold_storage_after                        = lifecycle.value.cold_storage_after
          delete_after                              = lifecycle.value.delete_after
          opt_in_to_archive_for_supported_resources = lifecycle.value.opt_in_to_archive_for_supported_resources
        }
      }

      dynamic "copy_action" {
        for_each = rule.value.copy_actions

        content {
          destination_vault_arn = copy_action.value.destination_vault_arn

          dynamic "lifecycle" {
            for_each = copy_action.value.lifecycle != null ? [copy_action.value.lifecycle] : []

            content {
              cold_storage_after                        = lifecycle.value.cold_storage_after
              delete_after                              = lifecycle.value.delete_after
              opt_in_to_archive_for_supported_resources = lifecycle.value.opt_in_to_archive_for_supported_resources
            }
          }
        }
      }
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = var.windows_vss_enabled ? [true] : []

    content {
      backup_options = {
        WindowsVSS = "enabled"
      }
      resource_type = "EC2"
    }
  }

  tags = var.tags
}

################################################################################
# Selections
################################################################################

resource "aws_backup_selection" "this" {
  for_each = var.create ? var.selections : {}

  region = var.region

  name         = coalesce(each.value.name, each.key)
  plan_id      = aws_backup_plan.this[0].id
  iam_role_arn = var.iam_role_arn

  resources     = each.value.resources
  not_resources = each.value.not_resources

  dynamic "selection_tag" {
    for_each = each.value.selection_tags

    content {
      type  = selection_tag.value.type
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions != null ? [each.value.conditions] : []

    content {
      dynamic "string_equals" {
        for_each = condition.value.string_equals

        content {
          key   = string_equals.value.key
          value = string_equals.value.value
        }
      }

      dynamic "string_like" {
        for_each = condition.value.string_like

        content {
          key   = string_like.value.key
          value = string_like.value.value
        }
      }

      dynamic "string_not_equals" {
        for_each = condition.value.string_not_equals

        content {
          key   = string_not_equals.value.key
          value = string_not_equals.value.value
        }
      }

      dynamic "string_not_like" {
        for_each = condition.value.string_not_like

        content {
          key   = string_not_like.value.key
          value = string_not_like.value.value
        }
      }
    }
  }
}
