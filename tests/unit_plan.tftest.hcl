# Unit tests of the plan sub-module with mocked providers, no AWS credentials needed.

mock_provider "aws" {}

variables {
  name         = "unit"
  vault_name   = "vault"
  iam_role_arn = "arn:aws:iam::123456789012:role/backup"
  rules = [{
    name     = "daily"
    schedule = "cron(0 5 * * ? *)"
  }]
}

run "defaults" {
  command = plan

  module {
    source = "./modules/plan"
  }

  assert {
    condition     = aws_backup_plan.this[0].name == "unit" && length(aws_backup_plan.this[0].rule) == 1 && length(aws_backup_plan.this[0].advanced_backup_setting) == 0 && length(aws_backup_selection.this) == 0
    error_message = "A single-rule plan without selection or VSS is expected."
  }

  assert {
    condition     = one(aws_backup_plan.this[0].rule).target_vault_name == "vault"
    error_message = "The rule must target the given vault."
  }
}

run "create_false" {
  command = plan

  module {
    source = "./modules/plan"
  }

  variables {
    create     = false
    selections = { all = { resources = ["*"] } }
  }

  assert {
    condition     = length(aws_backup_plan.this) == 0 && length(aws_backup_selection.this) == 0
    error_message = "`create = false` must disable every resource."
  }
}

run "complete" {
  command = apply

  module {
    source = "./modules/plan"
  }

  variables {
    windows_vss_enabled = true
    rules = [
      {
        name                         = "daily"
        schedule                     = "cron(0 5 * * ? *)"
        schedule_expression_timezone = "Europe/Paris"
        start_window                 = 60
        completion_window            = 180
        enable_continuous_backup     = true
        recovery_point_tags          = { Rule = "daily" }
        lifecycle                    = { delete_after = 35 }
      },
      {
        name      = "monthly"
        schedule  = "cron(0 5 1 * ? *)"
        lifecycle = { cold_storage_after = 30, delete_after = 365, opt_in_to_archive_for_supported_resources = true }
        copy_actions = [{
          destination_vault_arn = "arn:aws:backup:eu-west-3:123456789012:backup-vault:copy"
          lifecycle             = { delete_after = 365 }
        }]
      },
    ]
    selections = {
      by-arn = {
        resources     = ["arn:aws:dynamodb:eu-west-1:123456789012:table/orders"]
        not_resources = ["arn:aws:dynamodb:eu-west-1:123456789012:table/cache"]
      }
      by-tag = {
        name           = "tagged"
        resources      = ["*"]
        selection_tags = [{ type = "STRINGEQUALS", key = "backup", value = "true" }]
      }
      by-condition = {
        resources = ["*"]
        conditions = {
          string_equals     = [{ key = "aws:ResourceTag/env", value = "prod" }]
          string_like       = [{ key = "aws:ResourceTag/team", value = "data*" }]
          string_not_equals = [{ key = "aws:ResourceTag/backup", value = "false" }]
          string_not_like   = [{ key = "aws:ResourceTag/tmp", value = "*" }]
        }
      }
    }
  }

  assert {
    condition     = length(aws_backup_plan.this[0].rule) == 2 && length(aws_backup_plan.this[0].advanced_backup_setting) == 1
    error_message = "Two rules and the VSS setting are expected."
  }

  assert {
    condition     = alltrue([for rule in aws_backup_plan.this[0].rule : rule.rule_name == "daily" ? rule.schedule_expression_timezone == "Europe/Paris" && rule.enable_continuous_backup == true && one(rule.lifecycle).delete_after == 35 : true])
    error_message = "The daily rule must carry its timezone, continuous backup and lifecycle."
  }

  assert {
    condition     = alltrue([for rule in aws_backup_plan.this[0].rule : rule.rule_name == "monthly" ? one(rule.lifecycle).cold_storage_after == 30 && length(rule.copy_action) == 1 && one(one(rule.copy_action).lifecycle).delete_after == 365 : true])
    error_message = "The monthly rule must carry its cold storage transition and copy action."
  }

  assert {
    condition     = length(aws_backup_selection.this) == 3 && aws_backup_selection.this["by-tag"].name == "tagged" && aws_backup_selection.this["by-arn"].name == "by-arn"
    error_message = "Selection names must default to the map key unless overridden."
  }

  assert {
    condition     = length(one(aws_backup_selection.this["by-condition"].condition).string_equals) == 1 && length(one(aws_backup_selection.this["by-condition"].condition).string_not_like) == 1
    error_message = "Conditions must be rendered."
  }

  assert {
    condition     = length(aws_backup_selection.this["by-tag"].selection_tag) == 1
    error_message = "Selection tags must be rendered."
  }
}

run "invalid_name" {
  command = plan

  module {
    source = "./modules/plan"
  }

  variables {
    name = "bad name"
  }

  expect_failures = [var.name]
}

run "invalid_iam_role_arn" {
  command = plan

  module {
    source = "./modules/plan"
  }

  variables {
    iam_role_arn = "role"
  }

  expect_failures = [var.iam_role_arn]
}

run "invalid_rules_empty" {
  command = plan

  module {
    source = "./modules/plan"
  }

  variables {
    rules = []
  }

  expect_failures = [var.rules]
}

run "invalid_rules_lifecycle" {
  command = plan

  module {
    source = "./modules/plan"
  }

  variables {
    rules = [{ name = "daily", lifecycle = { cold_storage_after = 30, delete_after = 100 } }]
  }

  expect_failures = [var.rules]
}

run "invalid_selection_tag_type" {
  command = plan

  module {
    source = "./modules/plan"
  }

  variables {
    selections = { bad = { selection_tags = [{ type = "STRINGLIKE", key = "k", value = "v" }] } }
  }

  expect_failures = [var.selections]
}
