# AWS Backup Plan Submodule

Terraform submodule which creates one backup plan with its rules and resource selections against an existing vault.

## Usage

```hcl
module "plan" {
  source = "bgauduch/backup/aws//modules/plan"

  name         = "daily"
  vault_name   = "application"
  iam_role_arn = "arn:aws:iam::123456789012:role/application-backup"

  rules = [{
    name     = "daily"
    schedule = "cron(0 5 * * ? *)"
    lifecycle = {
      delete_after = 35
    }
  }]

  selections = {
    tagged = {
      resources      = ["*"]
      selection_tags = [{ type = "STRINGEQUALS", key = "backup", value = "daily" }]
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.24 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.24 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create"></a> [create](#input\_create) | Determines whether resources will be created (affects all resources) | `bool` | `true` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | ARN of the IAM role assumed by AWS Backup for the selections | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the backup plan | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | List of backup rules: `name`, `schedule` (cron), `schedule_expression_timezone`, `start_window`, `completion_window`, `enable_continuous_backup`, `recovery_point_tags`, `target_logically_air_gapped_backup_vault_arn`, `lifecycle` (`cold_storage_after`, `delete_after`, `opt_in_to_archive_for_supported_resources`), `copy_actions[]` (`destination_vault_arn`, `lifecycle`) | <pre>list(object({<br/>    name                                         = string<br/>    schedule                                     = optional(string)<br/>    schedule_expression_timezone                 = optional(string)<br/>    start_window                                 = optional(number)<br/>    completion_window                            = optional(number)<br/>    enable_continuous_backup                     = optional(bool)<br/>    recovery_point_tags                          = optional(map(string))<br/>    target_logically_air_gapped_backup_vault_arn = optional(string)<br/>    lifecycle = optional(object({<br/>      cold_storage_after                        = optional(number)<br/>      delete_after                              = optional(number)<br/>      opt_in_to_archive_for_supported_resources = optional(bool)<br/>    }))<br/>    copy_actions = optional(list(object({<br/>      destination_vault_arn = string<br/>      lifecycle = optional(object({<br/>        cold_storage_after                        = optional(number)<br/>        delete_after                              = optional(number)<br/>        opt_in_to_archive_for_supported_resources = optional(bool)<br/>      }))<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_selections"></a> [selections](#input\_selections) | Map of resource selections keyed by selection name: `name`, `resources`, `not_resources`, `selection_tags[]` (`type`, `key`, `value`), `conditions` (`string_equals[]`, `string_like[]`, `string_not_equals[]`, `string_not_like[]` of `key`/`value`) | <pre>map(object({<br/>    name          = optional(string)<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    selection_tags = optional(list(object({<br/>      type  = string<br/>      key   = string<br/>      value = string<br/>    })), [])<br/>    conditions = optional(object({<br/>      string_equals     = optional(list(object({ key = string, value = string })), [])<br/>      string_like       = optional(list(object({ key = string, value = string })), [])<br/>      string_not_equals = optional(list(object({ key = string, value = string })), [])<br/>      string_not_like   = optional(list(object({ key = string, value = string })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name) | Name of the backup vault targeted by the rules | `string` | n/a | yes |
| <a name="input_windows_vss_enabled"></a> [windows\_vss\_enabled](#input\_windows\_vss\_enabled) | Determines whether Windows VSS backup is enabled for EC2 instances | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the backup plan |
| <a name="output_id"></a> [id](#output\_id) | The ID of the backup plan |
| <a name="output_selection_ids"></a> [selection\_ids](#output\_selection\_ids) | Map of backup selection IDs, keyed by selection key |
| <a name="output_version"></a> [version](#output\_version) | Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan |
<!-- END_TF_DOCS -->
