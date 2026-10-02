provider "aws" {
  region = local.region
}

data "aws_partition" "current" {}

locals {
  region = "eu-west-1"
  name   = "backup-ex-${basename(path.cwd)}"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-backup"
  }
}

################################################################################
# Plan Module, against a vault and a role managed elsewhere
################################################################################

module "plan" {
  source = "../../modules/plan"

  name         = local.name
  vault_name   = aws_backup_vault.existing.name
  iam_role_arn = aws_iam_role.existing.arn

  rules = [
    {
      name              = "hourly"
      schedule          = "cron(0 * * * ? *)"
      start_window      = 60
      completion_window = 120
      lifecycle = {
        delete_after = 7
      }
    },
    {
      name     = "weekly"
      schedule = "cron(0 5 ? * SUN *)"
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 180
      }
    },
  ]

  selections = {
    tables = {
      resources = [aws_dynamodb_table.this.arn]
    }
    tagged = {
      resources      = ["*"]
      selection_tags = [{ type = "STRINGEQUALS", key = "backup", value = local.name }]
    }
  }

  tags = local.tags

  depends_on = [aws_iam_role_policy_attachment.existing]
}

################################################################################
# Backup Module, plans only, against the same vault and role
################################################################################

module "backup" {
  source = "../.."

  name = "${local.name}-root"

  create_vault        = false
  existing_vault_name = aws_backup_vault.existing.name

  create_iam_role = false
  iam_role_arn    = aws_iam_role.existing.arn

  plans = {
    weekly = {
      name = "${local.name}-weekly"
      rules = [{
        name     = "weekly"
        schedule = "cron(0 6 ? * SAT *)"
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

  depends_on = [aws_iam_role_policy_attachment.existing]
}

################################################################################
# Supporting resources: the existing vault and role
################################################################################

resource "aws_backup_vault" "existing" {
  name          = local.name
  force_destroy = true

  tags = local.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    # Source: https://docs.aws.amazon.com/aws-backup/latest/devguide/iam-service-roles.html (2026-10-03)
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "existing" {
  name               = "${local.name}-backup"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "existing" {
  role = aws_iam_role.existing.name
  # Source: https://docs.aws.amazon.com/aws-backup/latest/devguide/security-iam-awsmanpol.html (2026-10-03)
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

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
