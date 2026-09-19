provider "aws" {
  region = local.region
}

locals {
  region           = "eu-west-1"
  region_secondary = "eu-west-3"
  name             = "backup-ex-${basename(path.cwd)}"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/bgauduch/terraform-aws-backup"
  }
}

################################################################################
# Secondary vault, copy destination in another region
################################################################################

module "backup_secondary" {
  source = "../.."

  region = local.region_secondary

  name                = "${local.name}-secondary"
  vault_force_destroy = true

  # The secondary vault only stores copies: no plan, no role
  create_iam_role = false
  iam_role_arn    = module.backup.iam_role_arn

  tags = local.tags
}

################################################################################
# Primary vault and plan copying recovery points to the secondary region
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
        copy_actions = [{
          destination_vault_arn = module.backup_secondary.vault_arn
          lifecycle = {
            delete_after = 90
          }
        }]
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
