locals {
  create_iam_role = var.create && var.create_iam_role

  iam_role_arn = local.create_iam_role ? aws_iam_role.this[0].arn : var.iam_role_arn

  iam_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
  iam_role_policy_arns = toset(concat(
    [
      "${local.iam_policy_prefix}/service-role/AWSBackupServiceRolePolicyForBackup",
      "${local.iam_policy_prefix}/service-role/AWSBackupServiceRolePolicyForRestores",
    ],
    var.iam_role_attach_s3_policies ? [
      "${local.iam_policy_prefix}/AWSBackupServiceRolePolicyForS3Backup",
      "${local.iam_policy_prefix}/AWSBackupServiceRolePolicyForS3Restore",
    ] : [],
    var.iam_role_additional_policy_arns,
  ))
}

################################################################################
# IAM role assumed by AWS Backup for backup and restore jobs
################################################################################

data "aws_iam_policy_document" "assume_role" {
  count = local.create_iam_role ? 1 : 0

  statement {
    sid     = "BackupServiceAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = local.create_iam_role ? 1 : 0

  name                 = coalesce(var.iam_role_name, "${var.name}-backup")
  path                 = var.iam_role_path
  description          = "AWS Backup service role for backup and restore jobs"
  assume_role_policy   = data.aws_iam_policy_document.assume_role[0].json
  permissions_boundary = var.iam_role_permissions_boundary

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.create_iam_role ? local.iam_role_policy_arns : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "additional" {
  count = local.create_iam_role && var.create_iam_role_additional_policy ? 1 : 0

  name   = "additional"
  role   = aws_iam_role.this[0].name
  policy = var.iam_role_additional_policy_json
}
