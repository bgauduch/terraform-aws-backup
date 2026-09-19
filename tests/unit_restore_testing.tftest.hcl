# Unit tests of the restore-testing sub-module with mocked providers, no AWS credentials needed.

mock_provider "aws" {}

variables {
  name                = "unit-restore"
  schedule_expression = "cron(0 8 ? * MON *)"
  include_vaults      = ["*"]
  iam_role_arn        = "arn:aws:iam::123456789012:role/backup"
  selections = {
    dynamodb = {
      protected_resource_type = "DynamoDB"
      protected_resource_arns = ["*"]
    }
  }
}

run "defaults" {
  command = plan

  module {
    source = "./modules/restore-testing"
  }

  assert {
    condition     = aws_backup_restore_testing_plan.this[0].name == "unit_restore" && one(aws_backup_restore_testing_plan.this[0].recovery_point_selection).algorithm == "LATEST_WITHIN_WINDOW" && one(aws_backup_restore_testing_plan.this[0].recovery_point_selection).selection_window_days == 7
    error_message = "Plan name must replace hyphens and defaults must apply."
  }

  assert {
    condition     = aws_backup_restore_testing_selection.this["dynamodb"].name == "dynamodb" && aws_backup_restore_testing_selection.this["dynamodb"].iam_role_arn == var.iam_role_arn
    error_message = "The selection must inherit the module role."
  }
}

run "create_false" {
  command = plan

  module {
    source = "./modules/restore-testing"
  }

  variables {
    create = false
  }

  assert {
    condition     = length(aws_backup_restore_testing_plan.this) == 0 && length(aws_backup_restore_testing_selection.this) == 0
    error_message = "`create = false` must disable every resource."
  }
}

run "conditions_and_overrides" {
  command = plan

  module {
    source = "./modules/restore-testing"
  }

  variables {
    recovery_point_selection_algorithm = "RANDOM_WITHIN_WINDOW"
    recovery_point_types               = ["SNAPSHOT", "CONTINUOUS"]
    selection_window_days              = 30
    start_window_hours                 = 4
    selections = {
      dynamodb-tagged = {
        name                    = "ddb"
        protected_resource_type = "DynamoDB"
        iam_role_arn            = "arn:aws:iam::123456789012:role/restore"
        protected_resource_conditions = {
          string_equals = [{ key = "aws:ResourceTag/backup", value = "true" }]
        }
        restore_metadata_overrides = { encryptionType = "Default" }
        validation_window_hours    = 2
      }
    }
  }

  assert {
    condition     = aws_backup_restore_testing_selection.this["dynamodb-tagged"].name == "ddb" && aws_backup_restore_testing_selection.this["dynamodb-tagged"].iam_role_arn == "arn:aws:iam::123456789012:role/restore" && aws_backup_restore_testing_selection.this["dynamodb-tagged"].validation_window_hours == 2
    error_message = "Selection overrides must be applied."
  }

  assert {
    condition     = length(one(aws_backup_restore_testing_selection.this["dynamodb-tagged"].protected_resource_conditions).string_equals) == 1
    error_message = "Protected resource conditions must be rendered."
  }
}

run "invalid_algorithm" {
  command = plan

  module {
    source = "./modules/restore-testing"
  }

  variables {
    recovery_point_selection_algorithm = "OLDEST"
  }

  expect_failures = [var.recovery_point_selection_algorithm]
}

run "invalid_selection_window" {
  command = plan

  module {
    source = "./modules/restore-testing"
  }

  variables {
    selection_window_days = 366
  }

  expect_failures = [var.selection_window_days]
}

run "invalid_selection_without_scope" {
  command = plan

  module {
    source = "./modules/restore-testing"
  }

  variables {
    selections = { ebs = { protected_resource_type = "EBS" } }
  }

  expect_failures = [var.selections]
}

run "invalid_selection_with_both_scopes" {
  command = plan

  module {
    source = "./modules/restore-testing"
  }

  variables {
    selections = {
      ebs = {
        protected_resource_type       = "EBS"
        protected_resource_arns       = ["*"]
        protected_resource_conditions = { string_equals = [{ key = "aws:ResourceTag/backup", value = "true" }] }
      }
    }
  }

  expect_failures = [var.selections]
}

run "invalid_selection_without_role" {
  command = plan

  module {
    source = "./modules/restore-testing"
  }

  variables {
    iam_role_arn = null
  }

  expect_failures = [var.selections]
}
