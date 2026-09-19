# Integration tests of the plan sub-module against a real AWS account. Every run is destroyed by the test framework.

provider "aws" {
  region = "eu-west-1"
}

run "setup" {
  module {
    source = "./tests/setup/random"
  }
}

run "account" {
  module {
    source = "./tests/setup/account"
  }
}

run "vault" {
  module {
    source = "./tests/setup/vault"
  }

  variables {
    name = "it-${run.setup.id}-plan"
  }
}

run "role" {
  module {
    source = "./tests/setup/iam_role"
  }

  variables {
    name = "it-${run.setup.id}-plan"
  }
}

run "plan" {
  module {
    source = "./modules/plan"
  }

  variables {
    name         = "it-${run.setup.id}"
    vault_name   = run.vault.name
    iam_role_arn = run.role.arn
    rules = [
      {
        name                         = "daily"
        schedule                     = "cron(0 5 * * ? *)"
        schedule_expression_timezone = "Europe/Paris"
        start_window                 = 60
        completion_window            = 180
        lifecycle                    = { delete_after = 35 }
      },
      {
        name      = "monthly"
        schedule  = "cron(0 5 1 * ? *)"
        lifecycle = { cold_storage_after = 30, delete_after = 365 }
      },
    ]
    selections = {
      by-arn = { resources = ["arn:aws:dynamodb:eu-west-1:${run.account.id}:table/orders"] }
      by-tag = {
        resources      = ["*"]
        selection_tags = [{ type = "STRINGEQUALS", key = "backup", value = "true" }]
      }
      by-condition = {
        resources  = ["*"]
        conditions = { string_equals = [{ key = "aws:ResourceTag/backup", value = "true" }] }
      }
    }
  }

  assert {
    condition     = can(regex("^arn:aws:backup:eu-west-1:[0-9]{12}:backup-plan:", aws_backup_plan.this[0].arn)) && length(aws_backup_plan.this[0].rule) == 2
    error_message = "The plan must be created with two rules."
  }

  assert {
    condition     = length(aws_backup_selection.this) == 3 && alltrue([for selection in aws_backup_selection.this : selection.plan_id == aws_backup_plan.this[0].id])
    error_message = "The three selections must be attached to the plan."
  }
}
