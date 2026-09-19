################################################################################
# Audit Manager framework
################################################################################

resource "aws_backup_framework" "this" {
  count = var.create ? 1 : 0

  region = var.region

  name        = replace(var.name, "-", "_")
  description = var.description

  dynamic "control" {
    for_each = var.controls

    content {
      name = control.key

      dynamic "input_parameter" {
        for_each = control.value.input_parameters

        content {
          name  = input_parameter.key
          value = input_parameter.value
        }
      }

      dynamic "scope" {
        for_each = control.value.scope != null ? [control.value.scope] : []

        content {
          compliance_resource_ids   = scope.value.compliance_resource_ids
          compliance_resource_types = scope.value.compliance_resource_types
          tags                      = scope.value.tags
        }
      }
    }
  }

  tags = var.tags

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }
}
