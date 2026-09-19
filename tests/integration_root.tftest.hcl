# Integration tests of the root module against a real AWS account. Every run is destroyed by the test framework.

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

run "vault_role_plan" {
  variables {
    name                          = "it-${run.setup.id}"
    vault_force_destroy           = true
    vault_lock_enabled            = true
    vault_lock_max_retention_days = 365
    vault_copy_source_account_ids = [run.account.id]
    plans = {
      daily = {
        rules = [{
          name     = "daily"
          schedule = "cron(0 5 * * ? *)"
          lifecycle = {
            delete_after = 35
          }
        }]
        selections = {
          tagged = {
            resources      = ["*"]
            selection_tags = [{ type = "STRINGEQUALS", key = "backup", value = "it-${run.setup.id}" }]
          }
        }
      }
    }
  }

  assert {
    condition     = aws_backup_vault.this[0].name == "it-${run.setup.id}" && can(regex("^arn:aws:backup:eu-west-1:[0-9]{12}:backup-vault:it-", aws_backup_vault.this[0].arn))
    error_message = "The vault must be created with the given name."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.this[0].backup_vault_name == aws_backup_vault.this[0].name
    error_message = "The vault lock must apply to the vault."
  }

  assert {
    condition     = aws_backup_vault_policy.this[0].backup_vault_name == aws_backup_vault.this[0].name
    error_message = "The vault policy must apply to the vault."
  }

  assert {
    condition     = aws_iam_role.this[0].name == "it-${run.setup.id}-backup" && length(aws_iam_role_policy_attachment.this) == 4
    error_message = "The IAM role must be created with the managed policies."
  }

  assert {
    condition     = can(regex("^arn:aws:backup:eu-west-1:[0-9]{12}:backup-plan:", output.plans["daily"].arn)) && length(output.selections) == 1
    error_message = "The plan and its selection must be created."
  }
}
