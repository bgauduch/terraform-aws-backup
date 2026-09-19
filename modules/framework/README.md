# AWS Backup Framework Submodule

Terraform submodule which creates an AWS Backup Audit Manager framework made of the given controls. An active AWS Config recorder is required in the region; the module does not manage it. See the [framework example](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/framework).

## Usage

```hcl
module "framework" {
  source = "bgauduch/backup/aws//modules/framework"

  name = "application"

  controls = {
    BACKUP_RECOVERY_POINT_ENCRYPTED = {}
    BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK = {
      input_parameters = { requiredRetentionDays = "35" }
    }
    BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN = {
      scope = { compliance_resource_types = ["DynamoDB"] }
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_backup_framework.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_framework) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_controls"></a> [controls](#input\_controls) | Map of controls keyed by AWS Backup Audit Manager control name. Each control has optional `input_parameters` (map of parameter name to value) and an optional `scope` (`compliance_resource_ids`, `compliance_resource_types`, `tags` with a single entry) | <pre>map(object({<br/>    input_parameters = optional(map(string), {})<br/>    scope = optional(object({<br/>      compliance_resource_ids   = optional(list(string))<br/>      compliance_resource_types = optional(list(string))<br/>      tags                      = optional(map(string))<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Determines whether resources will be created (affects all resources) | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the framework | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the framework. Hyphens are replaced by underscores | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create, update, and delete timeout configurations for the framework. AWS Backup deploys the underlying AWS Config rules asynchronously | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the framework |
| <a name="output_deployment_status"></a> [deployment\_status](#output\_deployment\_status) | The deployment status of the framework: `CREATE_IN_PROGRESS`, `UPDATE_IN_PROGRESS`, `DELETE_IN_PROGRESS`, `COMPLETED` or `FAILED` |
| <a name="output_id"></a> [id](#output\_id) | The name of the framework |
| <a name="output_status"></a> [status](#output\_status) | The framework consistency status: `ACTIVE`, `PARTIALLY_ACTIVE`, `INACTIVE` or `UNAVAILABLE` |
<!-- END_TF_DOCS -->
