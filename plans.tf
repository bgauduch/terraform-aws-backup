################################################################################
# Backup plans and resource selections
################################################################################

module "plan" {
  source = "./modules/plan"

  for_each = local.create ? var.plans : {}

  region = var.region

  name                = coalesce(each.value.name, each.key)
  vault_name          = local.target_vault_name
  iam_role_arn        = each.value.iam_role_arn != null ? each.value.iam_role_arn : local.iam_role_arn
  windows_vss_enabled = each.value.windows_vss_enabled
  scan_settings       = each.value.scan_settings
  rules               = each.value.rules
  selections          = each.value.selections

  tags = var.tags

  # IAM is eventually consistent: role policies are attached before the selections use the role
  # Source: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html (2026-10-03)
  depends_on = [aws_iam_role_policy_attachment.this]
}
