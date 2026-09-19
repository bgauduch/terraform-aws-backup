provider "aws" {
  region = local.region
}

locals {
  region = "eu-west-1"
  name   = "backup-ex-${basename(path.cwd)}"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/bgauduch/terraform-aws-backup"
  }
}

################################################################################
# Backup Module
################################################################################

module "backup" {
  source = "../.."

  name                = local.name
  vault_force_destroy = true

  plans = {
    daily = {
      rules = [{
        name              = "daily"
        schedule          = "cron(0 5 * * ? *)"
        start_window      = 60
        completion_window = 180
        lifecycle = {
          delete_after = 35
        }
      }]
      selections = {
        tables = {
          resources = [aws_dynamodb_table.this.arn]
        }
      }
    }
  }

  tags = local.tags
}

################################################################################
# Restore Testing Module
################################################################################

module "restore_testing" {
  source = "../../modules/restore-testing"

  name                = local.name
  schedule_expression = "cron(0 8 ? * MON *)"
  start_window_hours  = 4

  include_vaults        = [module.backup.vault_arn]
  recovery_point_types  = ["SNAPSHOT"]
  selection_window_days = 7

  # The module role carries the AWS managed restore policy required by restore tests
  iam_role_arn = module.backup.iam_role_arn

  selections = {
    dynamodb = {
      protected_resource_type = "DynamoDB"
      protected_resource_conditions = {
        string_equals = [{ key = "aws:ResourceTag/backup", value = local.name }]
      }
      restore_metadata_overrides = {
        encryptionType = "Default"
      }
      validation_window_hours = 1
    }
  }

  tags = local.tags
}

################################################################################
# Supporting resources
################################################################################

resource "aws_dynamodb_table" "this" {
  name         = local.name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.tags, { backup = local.name })
}
