# Unit tests of the framework sub-module with mocked providers, no AWS credentials needed.

mock_provider "aws" {}

variables {
  name = "unit-framework"
  controls = {
    BACKUP_RECOVERY_POINT_ENCRYPTED = {}
    BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK = {
      input_parameters = { requiredRetentionDays = "35" }
    }
    BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN = {
      scope = { compliance_resource_types = ["DynamoDB"] }
    }
  }
}

run "defaults" {
  command = apply

  module {
    source = "./modules/framework"
  }

  assert {
    condition     = aws_backup_framework.this[0].name == "unit_framework" && length(aws_backup_framework.this[0].control) == 3
    error_message = "Framework name must replace hyphens and carry every control."
  }

  assert {
    condition     = alltrue([for control in aws_backup_framework.this[0].control : control.name == "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK" ? length(control.input_parameter) == 1 : true])
    error_message = "Input parameters must be rendered."
  }

  assert {
    condition     = alltrue([for control in aws_backup_framework.this[0].control : control.name == "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN" ? length(one(control.scope).compliance_resource_types) == 1 : true])
    error_message = "Scopes must be rendered."
  }
}

run "create_false" {
  command = plan

  module {
    source = "./modules/framework"
  }

  variables {
    create = false
  }

  assert {
    condition     = length(aws_backup_framework.this) == 0
    error_message = "`create = false` must disable every resource."
  }
}

run "invalid_name" {
  command = plan

  module {
    source = "./modules/framework"
  }

  variables {
    name = "1framework"
  }

  expect_failures = [var.name]
}

run "invalid_control_name" {
  command = plan

  module {
    source = "./modules/framework"
  }

  variables {
    controls = { BACKUP_EVERYTHING = {} }
  }

  expect_failures = [var.controls]
}

run "invalid_controls_empty" {
  command = plan

  module {
    source = "./modules/framework"
  }

  variables {
    controls = {}
  }

  expect_failures = [var.controls]
}

run "invalid_scope_tags" {
  command = plan

  module {
    source = "./modules/framework"
  }

  variables {
    controls = {
      BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN = { scope = { tags = { a = "1", b = "2" } } }
    }
  }

  expect_failures = [var.controls]
}
