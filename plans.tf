################################################################################
# Backup plans and resource selections
################################################################################

module "plan" {
  source = "./modules/plan"

  for_each = var.create ? var.plans : {}

  region = var.region

  name                = coalesce(each.value.name, each.key)
  vault_name          = local.target_vault_name
  iam_role_arn        = coalesce(each.value.iam_role_arn, local.iam_role_arn)
  windows_vss_enabled = each.value.windows_vss_enabled
  rules               = each.value.rules
  selections          = each.value.selections

  tags = var.tags

  # Selections are validated by AWS Backup against the role permissions at creation time
  depends_on = [aws_iam_role_policy_attachment.this]
}
