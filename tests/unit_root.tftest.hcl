# Unit tests of the root module with mocked providers, no AWS credentials needed.

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/unit-backup"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name = "unit"
}

################################################################################
# Defaults
################################################################################

run "defaults" {
  command = apply

  assert {
    condition     = aws_backup_vault.this[0].name == "unit"
    error_message = "Vault name must default to `name`."
  }

  assert {
    condition     = aws_iam_role.this[0].name == "unit-backup"
    error_message = "IAM role name must default to `<name>-backup`."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 4
    error_message = "Backup, restore and the two S3 managed policies must be attached by default."
  }

  assert {
    condition     = length(aws_backup_vault_policy.this) == 0 && length(aws_backup_vault_lock_configuration.this) == 0 && length(aws_backup_vault_notifications.this) == 0 && length(aws_backup_logically_air_gapped_vault.this) == 0 && length(aws_iam_role_policy.additional) == 0
    error_message = "Optional resources must not be created by default."
  }

  assert {
    condition     = length(module.plan) == 0
    error_message = "No plan must be created by default."
  }
}

run "create_false" {
  command = plan

  variables {
    create = false
    plans = {
      daily = {
        rules = [{ name = "daily", schedule = "cron(0 5 * * ? *)" }]
      }
    }
  }

  assert {
    condition     = length(aws_backup_vault.this) == 0 && length(aws_iam_role.this) == 0 && length(aws_iam_role_policy_attachment.this) == 0 && length(module.plan) == 0
    error_message = "`create = false` must disable every resource."
  }
}

################################################################################
# Vault
################################################################################

run "existing_vault" {
  command = plan

  variables {
    create_vault        = false
    existing_vault_name = "shared"
  }

  assert {
    condition     = length(aws_backup_vault.this) == 0 && output.vault_name == "shared"
    error_message = "An existing vault must be targeted without creating one."
  }
}

run "vault_overrides" {
  command = apply

  variables {
    vault_name          = "custom"
    vault_kms_key_arn   = "arn:aws:kms:eu-west-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    vault_force_destroy = true
  }

  assert {
    condition     = aws_backup_vault.this[0].name == "custom" && aws_backup_vault.this[0].kms_key_arn == var.vault_kms_key_arn && aws_backup_vault.this[0].force_destroy == true
    error_message = "Vault overrides must be applied."
  }
}

run "vault_policy_from_copy_accounts" {
  command = plan

  variables {
    vault_copy_source_account_ids = ["123456789012", "210987654321"]
  }

  assert {
    condition     = length(aws_backup_vault_policy.this) == 1
    error_message = "A vault policy must be created when copy source accounts are given."
  }

  assert {
    condition     = length(data.aws_iam_policy_document.vault[0].statement) == 2
    error_message = "One statement per copy source account is expected."
  }
}

run "vault_policy_from_json" {
  command = plan

  variables {
    attach_vault_policy = true
    vault_policy = jsonencode({
      Version   = "2012-10-17"
      Statement = []
    })
  }

  assert {
    condition     = length(aws_backup_vault_policy.this) == 1
    error_message = "A vault policy must be created when a policy document is given."
  }
}

run "vault_lock_governance" {
  command = plan

  variables {
    vault_lock_enabled            = true
    vault_lock_min_retention_days = 7
    vault_lock_max_retention_days = 90
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.this[0].min_retention_days == 7 && aws_backup_vault_lock_configuration.this[0].max_retention_days == 90 && aws_backup_vault_lock_configuration.this[0].changeable_for_days == null
    error_message = "Governance mode lock must be created without a lock date."
  }
}

run "vault_notifications" {
  command = plan

  variables {
    vault_notifications_enabled       = true
    vault_notifications_sns_topic_arn = "arn:aws:sns:eu-west-1:123456789012:backup"
  }

  assert {
    condition     = aws_backup_vault_notifications.this[0].backup_vault_name == "unit" && length(aws_backup_vault_notifications.this[0].backup_vault_events) == 3
    error_message = "Notifications must target the module vault with the default events."
  }
}

run "air_gapped_vault" {
  command = plan

  variables {
    create_air_gapped_vault = true
  }

  assert {
    condition     = aws_backup_logically_air_gapped_vault.this[0].name == "unit-air-gapped" && aws_backup_logically_air_gapped_vault.this[0].min_retention_days == 7 && aws_backup_logically_air_gapped_vault.this[0].max_retention_days == 35
    error_message = "Air-gapped vault must be created with the default name and retention."
  }
}

################################################################################
# IAM role
################################################################################

run "iam_role_provided" {
  command = plan

  variables {
    create_iam_role = false
    iam_role_arn    = "arn:aws:iam::123456789012:role/backup"
  }

  assert {
    condition     = length(aws_iam_role.this) == 0 && output.iam_role_arn == var.iam_role_arn
    error_message = "A provided role must be used as is."
  }
}

run "iam_role_policies" {
  command = plan

  variables {
    iam_role_name                     = "custom-role"
    iam_role_path                     = "/backup/"
    iam_role_permissions_boundary     = "arn:aws:iam::123456789012:policy/boundary"
    iam_role_attach_s3_policies       = false
    iam_role_additional_policy_arns   = ["arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForItemRestores"]
    create_iam_role_additional_policy = true
    iam_role_additional_policy_json = jsonencode({
      Version   = "2012-10-17"
      Statement = [{ Effect = "Allow", Action = "kms:Decrypt", Resource = "*" }]
    })
  }

  assert {
    condition     = aws_iam_role.this[0].name == "custom-role" && aws_iam_role.this[0].path == "/backup/" && aws_iam_role.this[0].permissions_boundary == var.iam_role_permissions_boundary
    error_message = "IAM role overrides must be applied."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 3 && length(aws_iam_role_policy.additional) == 1
    error_message = "Backup, restore and the additional managed policy plus the inline policy are expected."
  }
}

################################################################################
# Plans
################################################################################

run "plans" {
  command = plan

  variables {
    plans = {
      daily = {
        rules = [{ name = "daily", schedule = "cron(0 5 * * ? *)", lifecycle = { delete_after = 35 } }]
        selections = {
          tagged = { selection_tags = [{ type = "STRINGEQUALS", key = "backup", value = "true" }] }
        }
      }
      weekly = {
        name         = "weekly-override"
        iam_role_arn = "arn:aws:iam::123456789012:role/other"
        rules        = [{ name = "weekly", schedule = "cron(0 5 ? * SUN *)" }]
      }
    }
  }

  assert {
    condition     = length(module.plan) == 2
    error_message = "One plan module instance per map entry is expected."
  }
}

################################################################################
# Validations
################################################################################

run "invalid_name" {
  command = plan

  variables {
    name = "invalid name!"
  }

  expect_failures = [var.name]
}

run "invalid_vault_name" {
  command = plan

  variables {
    vault_name = "a"
  }

  expect_failures = [var.vault_name]
}

run "invalid_existing_vault_missing" {
  command = plan

  variables {
    create_vault = false
  }

  expect_failures = [var.existing_vault_name]
}

run "invalid_vault_kms_key_arn" {
  command = plan

  variables {
    vault_kms_key_arn = "not-an-arn"
  }

  expect_failures = [var.vault_kms_key_arn]
}

run "invalid_vault_policy_json" {
  command = plan

  variables {
    vault_policy = "{not json"
  }

  expect_failures = [var.vault_policy]
}

run "invalid_copy_source_account_ids" {
  command = plan

  variables {
    vault_copy_source_account_ids = ["12345"]
  }

  expect_failures = [var.vault_copy_source_account_ids]
}

run "invalid_lock_min_retention" {
  command = plan

  variables {
    vault_lock_min_retention_days = 0
  }

  expect_failures = [var.vault_lock_min_retention_days]
}

run "invalid_lock_max_below_min" {
  command = plan

  variables {
    vault_lock_min_retention_days = 30
    vault_lock_max_retention_days = 7
  }

  expect_failures = [var.vault_lock_max_retention_days]
}

run "invalid_lock_changeable_for_days" {
  command = plan

  variables {
    vault_lock_changeable_for_days = 2
  }

  expect_failures = [var.vault_lock_changeable_for_days]
}

run "invalid_notifications_without_topic" {
  command = plan

  variables {
    vault_notifications_enabled = true
  }

  expect_failures = [var.vault_notifications_sns_topic_arn]
}

run "invalid_additional_policy_without_json" {
  command = plan

  variables {
    create_iam_role_additional_policy = true
  }

  expect_failures = [var.iam_role_additional_policy_json]
}

run "invalid_sns_topic_arn" {
  command = plan

  variables {
    vault_notifications_sns_topic_arn = "arn:aws:sqs:eu-west-1:123456789012:queue"
  }

  expect_failures = [var.vault_notifications_sns_topic_arn]
}

run "invalid_notification_event" {
  command = plan

  variables {
    vault_notifications_events = ["BACKUP_JOB_EXPLODED"]
  }

  expect_failures = [var.vault_notifications_events]
}

run "invalid_air_gapped_retention" {
  command = plan

  variables {
    air_gapped_vault_min_retention_days = 6
  }

  expect_failures = [var.air_gapped_vault_min_retention_days]
}

run "invalid_air_gapped_max_below_min" {
  command = plan

  variables {
    air_gapped_vault_min_retention_days = 30
    air_gapped_vault_max_retention_days = 10
  }

  expect_failures = [var.air_gapped_vault_max_retention_days]
}

run "invalid_iam_role_arn_missing" {
  command = plan

  variables {
    create_iam_role = false
  }

  expect_failures = [var.iam_role_arn]
}

run "invalid_iam_role_arn" {
  command = plan

  variables {
    create_iam_role = false
    iam_role_arn    = "arn:aws:iam::123456789012:user/me"
  }

  expect_failures = [var.iam_role_arn]
}

run "invalid_permissions_boundary" {
  command = plan

  variables {
    iam_role_permissions_boundary = "boundary"
  }

  expect_failures = [var.iam_role_permissions_boundary]
}

run "invalid_additional_policy_json" {
  command = plan

  variables {
    iam_role_additional_policy_json = "nope"
  }

  expect_failures = [var.iam_role_additional_policy_json]
}

run "invalid_plan_without_rules" {
  command = plan

  variables {
    plans = {
      empty = { rules = [] }
    }
  }

  expect_failures = [var.plans]
}

run "invalid_plan_lifecycle_cold_storage" {
  command = plan

  variables {
    plans = {
      daily = {
        rules = [{ name = "daily", lifecycle = { cold_storage_after = 30, delete_after = 60 } }]
      }
    }
  }

  expect_failures = [var.plans]
}

run "invalid_plan_continuous_retention" {
  command = plan

  variables {
    plans = {
      daily = {
        rules = [{ name = "daily", enable_continuous_backup = true, lifecycle = { delete_after = 36 } }]
      }
    }
  }

  expect_failures = [var.plans]
}

run "invalid_plan_copy_action_lifecycle" {
  command = plan

  variables {
    plans = {
      daily = {
        rules = [{
          name         = "daily"
          copy_actions = [{ destination_vault_arn = "arn:aws:backup:eu-west-3:123456789012:backup-vault:copy", lifecycle = { cold_storage_after = 10, delete_after = 20 } }]
        }]
      }
    }
  }

  expect_failures = [var.plans]
}

run "invalid_plan_iam_role_arn" {
  command = plan

  variables {
    plans = {
      daily = {
        iam_role_arn = "role"
        rules        = [{ name = "daily" }]
      }
    }
  }

  expect_failures = [var.plans]
}
