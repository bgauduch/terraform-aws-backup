data "aws_partition" "current" {}

locals {
  create       = var.create && var.putin_khuylo
  create_vault = local.create && var.create_vault

  vault_name        = coalesce(var.vault_name, var.name)
  target_vault_name = local.create_vault ? aws_backup_vault.this[0].name : var.existing_vault_name

  create_vault_policy = local.create_vault && (var.attach_vault_policy || length(var.vault_copy_source_account_ids) > 0)
}

################################################################################
# Vault
################################################################################

resource "aws_backup_vault" "this" {
  count = local.create_vault ? 1 : 0

  region = var.region

  name          = local.vault_name
  kms_key_arn   = var.vault_kms_key_arn
  force_destroy = var.vault_force_destroy

  tags = var.tags
}

data "aws_iam_policy_document" "vault" {
  count = local.create_vault_policy ? 1 : 0

  source_policy_documents = var.attach_vault_policy ? [var.vault_policy] : []

  dynamic "statement" {
    for_each = toset(var.vault_copy_source_account_ids)

    content {
      sid    = "AllowCopyIntoBackupVaultFrom${statement.value}"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
      }

      actions   = ["backup:CopyIntoBackupVault"]
      resources = ["*"]
    }
  }
}

resource "aws_backup_vault_policy" "this" {
  count = local.create_vault_policy ? 1 : 0

  region = var.region

  backup_vault_name = aws_backup_vault.this[0].name
  policy            = data.aws_iam_policy_document.vault[0].json
}

resource "aws_backup_vault_lock_configuration" "this" {
  count = local.create_vault && var.vault_lock_enabled ? 1 : 0

  region = var.region

  backup_vault_name   = aws_backup_vault.this[0].name
  min_retention_days  = var.vault_lock_min_retention_days
  max_retention_days  = var.vault_lock_max_retention_days
  changeable_for_days = var.vault_lock_changeable_for_days

  lifecycle {
    precondition {
      condition     = var.vault_lock_max_retention_days == null || var.vault_lock_min_retention_days == null || try(var.vault_lock_max_retention_days >= var.vault_lock_min_retention_days, false)
      error_message = "`vault_lock_max_retention_days` must be greater than or equal to `vault_lock_min_retention_days`."
    }
  }
}

resource "aws_backup_vault_notifications" "this" {
  count = local.create && var.vault_notifications_enabled && (var.create_vault || var.existing_vault_name != null) ? 1 : 0

  region = var.region

  backup_vault_name   = local.target_vault_name
  sns_topic_arn       = var.vault_notifications_sns_topic_arn
  backup_vault_events = var.vault_notifications_events

  lifecycle {
    precondition {
      condition     = var.vault_notifications_sns_topic_arn != null
      error_message = "`vault_notifications_sns_topic_arn` is required when `vault_notifications_enabled` is `true`."
    }
  }
}

################################################################################
# Logically air-gapped vault
################################################################################

resource "aws_backup_logically_air_gapped_vault" "this" {
  count = local.create && var.air_gapped_vault_enabled ? 1 : 0

  region = var.region

  name               = coalesce(var.air_gapped_vault_name, "${var.name}-air-gapped")
  min_retention_days = var.air_gapped_vault_min_retention_days
  max_retention_days = var.air_gapped_vault_max_retention_days
  encryption_key_arn = var.air_gapped_vault_kms_key_arn

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.air_gapped_vault_max_retention_days >= var.air_gapped_vault_min_retention_days
      error_message = "`air_gapped_vault_max_retention_days` must be greater than or equal to `air_gapped_vault_min_retention_days`."
    }
  }
}
