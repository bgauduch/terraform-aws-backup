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
# Framework Module
################################################################################

module "framework" {
  source = "../../modules/framework"

  name        = local.name
  description = "Backup controls of the ${local.name} example"

  controls = {
    BACKUP_RECOVERY_POINT_ENCRYPTED                = {}
    BACKUP_RECOVERY_POINT_MANUAL_DELETION_DISABLED = {}
    BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK = {
      input_parameters = { requiredRetentionDays = "35" }
    }
    BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK = {
      input_parameters = {
        requiredFrequencyUnit  = "days"
        requiredFrequencyValue = "1"
        requiredRetentionDays  = "35"
      }
    }
    BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN = {
      scope = { compliance_resource_types = ["DynamoDB"] }
    }
  }

  # The underlying AWS Config rules are deployed asynchronously
  timeouts = {
    create = "20m"
    delete = "20m"
  }

  tags = local.tags

  # AWS Backup Audit Manager requires an active AWS Config recorder in the region
  depends_on = [aws_config_configuration_recorder_status.this]
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

  tags = local.tags
}
