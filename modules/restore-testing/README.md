# AWS Backup Restore Testing Submodule

Terraform submodule which creates a restore testing plan and one selection per protected resource type. The IAM role must carry the restore permissions of the selected resource types, `AWSBackupServiceRolePolicyForRestores` at least. Each selection targets either explicit resource ARNs or tag conditions.

## Usage

```hcl
module "restore_testing" {
  source = "bgauduch/backup/aws//modules/restore-testing"

  name                = "application"
  schedule_expression = "cron(0 8 ? * MON *)"
  include_vaults      = ["arn:aws:backup:eu-west-1:123456789012:backup-vault:application"]
  iam_role_arn        = "arn:aws:iam::123456789012:role/application-backup"

  selections = {
    dynamodb = {
      protected_resource_type = "DynamoDB"
      protected_resource_conditions = {
        string_equals = [{ key = "aws:ResourceTag/backup", value = "true" }]
      }
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
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
| [aws_backup_restore_testing_plan.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_restore_testing_plan) | resource |
| [aws_backup_restore_testing_selection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_restore_testing_selection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_create"></a> [create](#input\_create) | Determines whether resources will be created (affects all resources) | `bool` | `true` | no |
| <a name="input_exclude_vaults"></a> [exclude\_vaults](#input\_exclude\_vaults) | List of backup vault ARNs excluded from the recovery point selection | `list(string)` | `null` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | ARN of the IAM role assumed by AWS Backup for the restore tests. It must carry the restore permissions of the protected resource types. Can be overridden per selection | `string` | `null` | no |
| <a name="input_include_vaults"></a> [include\_vaults](#input\_include\_vaults) | List of backup vault ARNs the recovery points are selected from, or `["*"]` for all vaults | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the restore testing plan. Hyphens are replaced by underscores | `string` | n/a | yes |
| <a name="input_recovery_point_selection_algorithm"></a> [recovery\_point\_selection\_algorithm](#input\_recovery\_point\_selection\_algorithm) | Algorithm used to select the recovery points. Valid values: `LATEST_WITHIN_WINDOW`, `RANDOM_WITHIN_WINDOW` | `string` | `"LATEST_WITHIN_WINDOW"` | no |
| <a name="input_recovery_point_types"></a> [recovery\_point\_types](#input\_recovery\_point\_types) | List of recovery point types selected. Valid values: `SNAPSHOT`, `CONTINUOUS` | `list(string)` | <pre>[<br/>  "SNAPSHOT"<br/>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | Cron expression that defines when the restore tests run | `string` | n/a | yes |
| <a name="input_schedule_expression_timezone"></a> [schedule\_expression\_timezone](#input\_schedule\_expression\_timezone) | Timezone of the schedule expression | `string` | `null` | no |
| <a name="input_selection_window_days"></a> [selection\_window\_days](#input\_selection\_window\_days) | Number of days, between 1 and 365, within which the recovery points are selected | `number` | `7` | no |
| <a name="input_selections"></a> [selections](#input\_selections) | Map of restore testing selections keyed by selection name, one per protected resource type: `name`, `protected_resource_type`, `iam_role_arn`, exactly one of `protected_resource_arns` or `protected_resource_conditions` (`string_equals[]`, `string_not_equals[]` of `key`/`value`, keys prefixed by `aws:ResourceTag/`), `restore_metadata_overrides`, `validation_window_hours` | <pre>map(object({<br/>    name                    = optional(string)<br/>    protected_resource_type = string<br/>    iam_role_arn            = optional(string)<br/>    protected_resource_arns = optional(list(string))<br/>    protected_resource_conditions = optional(object({<br/>      string_equals     = optional(list(object({ key = string, value = string })), [])<br/>      string_not_equals = optional(list(object({ key = string, value = string })), [])<br/>    }))<br/>    restore_metadata_overrides = optional(map(string))<br/>    validation_window_hours    = optional(number)<br/>  }))</pre> | `{}` | no |
| <a name="input_start_window_hours"></a> [start\_window\_hours](#input\_start\_window\_hours) | Number of hours during which the restore tests can start, between 1 and 168 | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_plan_arn"></a> [plan\_arn](#output\_plan\_arn) | The ARN of the restore testing plan |
| <a name="output_plan_name"></a> [plan\_name](#output\_plan\_name) | The name of the restore testing plan |
| <a name="output_selection_names"></a> [selection\_names](#output\_selection\_names) | Map of restore testing selection names, keyed by selection key |
<!-- END_TF_DOCS -->
