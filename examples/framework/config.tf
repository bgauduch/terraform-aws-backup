################################################################################
# AWS Config recorder, one per region and account.
# Created only when the account has none: see `enable_config_recorder`.
################################################################################

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  create_config = var.enable_config_recorder
}

resource "aws_s3_bucket" "config" {
  count = local.create_config ? 1 : 0

  bucket        = "${local.name}-config-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "config" {
  count = local.create_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count = local.create_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "config_bucket" {
  count = local.create_config ? 1 : 0

  statement {
    sid       = "ConfigBucketAccess"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.config[0].arn]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid       = "ConfigDelivery"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.config[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "config" {
  count = local.create_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id
  policy = data.aws_iam_policy_document.config_bucket[0].json

  depends_on = [aws_s3_bucket_public_access_block.config]
}

data "aws_iam_policy_document" "config_assume_role" {
  count = local.create_config ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  count = local.create_config ? 1 : 0

  name               = "${local.name}-config"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role[0].json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count = local.create_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count = local.create_config ? 1 : 0

  name     = local.name
  role_arn = aws_iam_role.config[0].arn

  # Only the resource types evaluated by the backup controls are recorded
  recording_group {
    all_supported = false
    resource_types = [
      "AWS::Backup::BackupPlan",
      "AWS::Backup::BackupSelection",
      "AWS::Backup::BackupVault",
      "AWS::Backup::RecoveryPoint",
      "AWS::Config::ResourceCompliance",
      "AWS::DynamoDB::Table",
    ]
  }
}

resource "aws_config_delivery_channel" "this" {
  count = local.create_config ? 1 : 0

  name           = local.name
  s3_bucket_name = aws_s3_bucket.config[0].id

  depends_on = [aws_config_configuration_recorder.this, aws_s3_bucket_policy.config]
}

resource "aws_config_configuration_recorder_status" "this" {
  count = local.create_config ? 1 : 0

  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
