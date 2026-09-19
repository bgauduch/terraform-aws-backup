resource "aws_backup_vault" "this" {
  name          = var.name
  force_destroy = true
}
