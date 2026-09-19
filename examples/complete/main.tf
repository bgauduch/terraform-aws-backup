provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  region     = "eu-west-1"
  name       = "backup-ex-${basename(path.cwd)}"
  account_id = data.aws_caller_identity.current.account_id

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

  # Vault
  vault_kms_key_arn             = aws_kms_key.vault.arn
  vault_copy_source_account_ids = [local.account_id]
  vault_force_destroy           = true # Recovery points are deleted with the vault, for the example teardown only

  # Vault lock, governance mode: no lock date, no minimum retention so that recovery points stay deletable
  vault_lock_enabled            = true
  vault_lock_max_retention_days = 365

  # Notifications
  vault_notifications_enabled       = true
  vault_notifications_sns_topic_arn = aws_sns_topic.backup.arn
  vault_notifications_events        = ["BACKUP_JOB_FAILED", "COPY_JOB_FAILED", "RESTORE_JOB_FAILED", "RESTORE_JOB_COMPLETED"]

  # Logically air-gapped vault
  create_air_gapped_vault             = true
  air_gapped_vault_min_retention_days = 7
  air_gapped_vault_max_retention_days = 90

  # IAM role
  iam_role_additional_policy_arns   = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForItemRestores"]
  create_iam_role_additional_policy = true
  iam_role_additional_policy_json   = data.aws_iam_policy_document.role_kms.json

  # Plans
  plans = {
    daily = {
      rules = [
        {
          name                         = "daily"
          schedule                     = "cron(0 5 * * ? *)"
          schedule_expression_timezone = "Europe/Paris"
          start_window                 = 60
          completion_window            = 180
          recovery_point_tags          = { Rule = "daily" }
          lifecycle = {
            delete_after = 35
          }
        },
        {
          name     = "monthly"
          schedule = "cron(0 5 1 * ? *)"
          lifecycle = {
            cold_storage_after                        = 30
            delete_after                              = 365
            opt_in_to_archive_for_supported_resources = true
          }
        },
      ]
      selections = {
        by-tag = {
          resources      = ["*"]
          selection_tags = [{ type = "STRINGEQUALS", key = "backup", value = local.name }]
        }
        by-arn = {
          resources = [aws_dynamodb_table.this.arn]
          conditions = {
            string_not_equals = [{ key = "aws:ResourceTag/backup", value = "false" }]
          }
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

  tags = merge(local.tags, { backup = local.name })
}

# KMS key of the vault: the module role encrypts and decrypts recovery points through AWS Backup grants
data "aws_iam_policy_document" "vault_key" {
  statement {
    sid       = "AccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid    = "BackupRoleUsage"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"]
    }

    # The role ARN is matched by condition so that the key policy stays valid when the role is recreated
    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.name}-backup"]
    }
  }

  statement {
    sid       = "BackupRoleGrants"
    effect    = "Allow"
    actions   = ["kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.name}-backup"]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "vault" {
  description             = "${local.name} backup vault"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.vault_key.json

  tags = local.tags
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.vault.key_id
}

# Identity permissions of the module role on the vault key
data "aws_iam_policy_document" "role_kms" {
  statement {
    sid    = "VaultKeyUsage"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    resources = [aws_kms_key.vault.arn]
  }
}

resource "aws_sns_topic" "backup" {
  name              = local.name
  kms_master_key_id = "alias/aws/sns"

  tags = local.tags
}

data "aws_iam_policy_document" "sns" {
  statement {
    sid       = "BackupPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.backup.arn]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "backup" {
  arn    = aws_sns_topic.backup.arn
  policy = data.aws_iam_policy_document.sns.json
}
