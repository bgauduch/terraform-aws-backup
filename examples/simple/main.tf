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

  name = local.name

  # Recovery points are deleted with the vault, for the example teardown only
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
        tagged = {
          resources      = ["*"]
          selection_tags = [{ type = "STRINGEQUALS", key = "backup", value = local.name }]
        }
      }
    }
  }

  tags = local.tags
}
