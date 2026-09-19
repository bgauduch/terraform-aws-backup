# Integration tests of the root module against an existing vault and role. Every run is destroyed by the test framework.

provider "aws" {
  region = "eu-west-1"
}

run "setup" {
  module {
    source = "./tests/setup/random"
  }
}

run "existing_vault_setup" {
  module {
    source = "./tests/setup/vault"
  }

  variables {
    name = "it-${run.setup.id}-existing"
  }
}

run "existing_role_setup" {
  module {
    source = "./tests/setup/iam_role"
  }

  variables {
    name = "it-${run.setup.id}-existing"
  }
}

run "existing_vault_and_role" {
  variables {
    name                = "it-${run.setup.id}-reuse"
    create_vault        = false
    existing_vault_name = run.existing_vault_setup.name
    create_iam_role     = false
    iam_role_arn        = run.existing_role_setup.arn
    plans = {
      weekly = {
        rules = [{
          name     = "weekly"
          schedule = "cron(0 5 ? * SUN *)"
        }]
        selections = {
          all = { resources = ["*"] }
        }
      }
    }
  }

  assert {
    condition     = length(aws_backup_vault.this) == 0 && length(aws_iam_role.this) == 0
    error_message = "Neither vault nor role must be created."
  }

  assert {
    condition     = output.vault_name == run.existing_vault_setup.name && output.iam_role_arn == run.existing_role_setup.arn
    error_message = "The existing vault and role must be used."
  }

  assert {
    condition     = can(regex("^arn:aws:backup:eu-west-1:[0-9]{12}:backup-plan:", output.plans["weekly"].arn))
    error_message = "The plan must be created against the existing vault."
  }
}
