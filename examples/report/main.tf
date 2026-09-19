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
# Report Module
################################################################################

module "report" {
  source = "../../modules/report"

  name           = local.name
  s3_bucket_name = aws_s3_bucket.reports.id
  s3_key_prefix  = "backup"

  report_templates = ["BACKUP_JOB_REPORT", "COPY_JOB_REPORT", "RESTORE_JOB_REPORT"]
  formats          = ["CSV", "JSON"]
  descriptions = {
    BACKUP_JOB_REPORT = "Daily backup jobs"
  }

  tags = local.tags

  depends_on = [aws_s3_bucket_policy.reports]
}

################################################################################
# Supporting resources: report delivery bucket
################################################################################

resource "aws_s3_bucket" "reports" {
  bucket        = "${local.name}-${local.account_id}"
  force_destroy = true # Reports are deleted with the bucket, for the example teardown only

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Reports are written by the AWS Backup Audit Manager service-linked role, matched by ARN condition since it is created by the first report plan
data "aws_iam_policy_document" "reports" {
  statement {
    sid       = "BackupReportsDelivery"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.reports.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/aws-service-role/reports.backup.amazonaws.com/AWSServiceRoleForBackupReports"]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.reports.arn, "${aws_s3_bucket.reports.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "reports" {
  bucket = aws_s3_bucket.reports.id
  policy = data.aws_iam_policy_document.reports.json

  depends_on = [aws_s3_bucket_public_access_block.reports]
}
