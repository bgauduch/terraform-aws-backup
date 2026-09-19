# AWS Backup Terraform module

Terraform module which creates AWS Backup resources on AWS: vault, vault lock, vault policy, notifications, logically air-gapped vault, IAM role, backup plans and resource selections. Report plans, restore testing plans and Audit Manager frameworks are provided as standalone submodules.

## Usage

```hcl
module "backup" {
  source = "bgauduch/backup/aws"

  name = "application"

  vault_kms_key_arn = "arn:aws:kms:eu-west-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  vault_lock_enabled            = true
  vault_lock_min_retention_days = 7
  vault_lock_max_retention_days = 365

  plans = {
    daily = {
      rules = [{
        name              = "daily"
        schedule          = "cron(0 5 * * ? *)"
        start_window      = 60
        completion_window = 180
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
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

## Features

- Backup vault encrypted with the AWS managed key or a customer managed KMS key, with vault lock in governance or compliance mode, vault policy for cross-account copies and SNS notifications
- Logically air-gapped vault
- IAM role assumed by AWS Backup with the AWS managed backup and restore policies, extensible with managed or inline policies, or an existing role
- Backup plans with multiple rules, lifecycle with cold storage and archive tiers, copy actions across regions and accounts, Windows VSS
- Resource selections by ARN, by tag and by condition
- Submodules for standalone plans, report plans, restore testing plans and Audit Manager frameworks
- Native `terraform test` suite with mocked providers and an end-to-end backup and restore test with Terratest

## Conditional Creation

The module supports conditional resource creation:

```hcl
module "backup" {
  source = "bgauduch/backup/aws"

  create = false
}
```

## Vault encryption

The vault is encrypted with the AWS managed key `aws/backup` unless `vault_kms_key_arn` is set. The module never creates a KMS key: the key policy of a customer managed key must allow the IAM role assumed by AWS Backup to use the key and to create grants for AWS resources. See the [complete example](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/complete) for a working key policy.

## Vault policy and cross-account copy

`vault_copy_source_account_ids` adds a statement allowing each account to copy recovery points into the vault. `attach_vault_policy` and `vault_policy` attach a full policy document, merged with the generated statements.

```hcl
module "backup" {
  source = "bgauduch/backup/aws"

  name = "central"

  vault_copy_source_account_ids = ["111111111111", "222222222222"]
}
```

## Vault lock

`vault_lock_enabled` creates a vault lock in governance mode: retention bounds are enforced, and the lock can be removed by a principal holding `backup:DeleteBackupVaultLockConfiguration`. Setting `vault_lock_changeable_for_days` switches the lock to compliance mode: once the lock date is reached, neither the lock nor the vault can be deleted, by anyone. See the [AWS Backup Vault Lock documentation](https://docs.aws.amazon.com/aws-backup/latest/devguide/vault-lock.html).

Any lock, governance mode included, rejects manual deletion of recovery points and on-demand backup jobs whose lifecycle falls outside the retention bounds. `vault_force_destroy` cannot empty a locked vault: remove the lock configuration first.

## Notifications

`vault_notifications_enabled` and `vault_notifications_sns_topic_arn` subscribe an SNS topic to the vault events listed in `vault_notifications_events`. The topic policy must allow `backup.amazonaws.com` to publish; the module does not manage the topic.

## IAM role

The module creates an IAM role assumed by `backup.amazonaws.com` with the AWS managed backup and restore policies, including the S3 ones unless `iam_role_attach_s3_policies` is `false`. Extra managed policies go in `iam_role_additional_policy_arns` and an inline policy in `iam_role_additional_policy_json` with `create_iam_role_additional_policy`, for KMS permissions on the keys of the protected resources for example. Set `create_iam_role = false` and `iam_role_arn` to use an existing role; a plan can also override the role through `plans.<key>.iam_role_arn`.

## Plans and selections

`plans` is a map of backup plans. Each plan holds a list of `rules`, with a schedule, windows, lifecycle and copy actions, and a map of `selections` assigning resources by ARN, by tag or by condition. Plans and selections are created through the [plan sub-module](https://github.com/bgauduch/terraform-aws-backup/tree/main/modules/plan), which can be used on its own against an existing vault.

## Existing vault

Set `create_vault = false` and `existing_vault_name` to target a vault managed elsewhere. Plans and notifications then use that vault; the lock configuration and the vault policy are not managed.

## Submodules

- [plan](https://github.com/bgauduch/terraform-aws-backup/tree/main/modules/plan) - Manages one backup plan with its rules and resource selections against an existing vault
- [report](https://github.com/bgauduch/terraform-aws-backup/tree/main/modules/report) - Manages report plans delivered to an existing S3 bucket
- [restore-testing](https://github.com/bgauduch/terraform-aws-backup/tree/main/modules/restore-testing) - Manages a restore testing plan and its selections
- [framework](https://github.com/bgauduch/terraform-aws-backup/tree/main/modules/framework) - Manages an AWS Backup Audit Manager framework and its controls

## Examples

- [Simple](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/simple) - Vault, IAM role and a daily plan selecting resources by tag
- [Complete](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/complete) - Customer managed KMS key, governance vault lock, cross-account copy policy, SNS notifications, air-gapped vault, multi-rule plan
- [Cross-region copy](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/cross-region-copy) - Secondary vault in another region fed by a copy action
- [Plan](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/plan) - Plan submodule against an existing vault and role
- [Report](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/report) - Job report plans delivered to an S3 bucket
- [Restore testing](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/restore-testing) - Weekly restore tests of the protected DynamoDB tables
- [Framework](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/framework) - AWS Backup Audit Manager controls

## Module Wrappers

For managing multiple similar resources, see [wrappers](https://github.com/bgauduch/terraform-aws-backup/tree/main/wrappers).

## Tests

Unit tests run against mocked providers and need no AWS credentials:

```bash
terraform init -backend=false
terraform test -filter=tests/unit_root.tftest.hcl
```

Integration tests (`tests/integration_*.tftest.hcl`) and the Terratest suite in [`tests/e2e`](https://github.com/bgauduch/terraform-aws-backup/tree/main/tests/e2e) deploy the examples in a real account, run an on-demand backup and restore of a DynamoDB table, and destroy everything, recovery points included:

```bash
terraform test -filter=tests/integration_root.tftest.hcl
cd tests/e2e && go test -v -timeout 120m ./...
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.24 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.24 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_plan"></a> [plan](#module\_plan) | ./modules/plan | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_backup_logically_air_gapped_vault.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_logically_air_gapped_vault) | resource |
| [aws_backup_vault.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_lock_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |
| [aws_backup_vault_notifications.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_notifications) | resource |
| [aws_backup_vault_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name used as the default for the vault, the IAM role and the air-gapped vault | `string` | n/a | yes |
| <a name="input_air_gapped_vault_kms_key_arn"></a> [air\_gapped\_vault\_kms\_key\_arn](#input\_air\_gapped\_vault\_kms\_key\_arn) | ARN of the KMS key used to encrypt the logically air-gapped vault. Defaults to the AWS managed key | `string` | `null` | no |
| <a name="input_air_gapped_vault_max_retention_days"></a> [air\_gapped\_vault\_max\_retention\_days](#input\_air\_gapped\_vault\_max\_retention\_days) | The maximum retention period, in days, that the logically air-gapped vault retains its recovery points | `number` | `35` | no |
| <a name="input_air_gapped_vault_min_retention_days"></a> [air\_gapped\_vault\_min\_retention\_days](#input\_air\_gapped\_vault\_min\_retention\_days) | The minimum retention period, in days, that the logically air-gapped vault retains its recovery points | `number` | `7` | no |
| <a name="input_air_gapped_vault_name"></a> [air\_gapped\_vault\_name](#input\_air\_gapped\_vault\_name) | Name of the logically air-gapped vault. Defaults to `<name>-air-gapped` | `string` | `null` | no |
| <a name="input_attach_vault_policy"></a> [attach\_vault\_policy](#input\_attach\_vault\_policy) | Determines whether `vault_policy` is attached to the backup vault. The statements generated from `vault_copy_source_account_ids` are attached regardless | `bool` | `false` | no |
| <a name="input_create"></a> [create](#input\_create) | Determines whether resources will be created (affects all resources) | `bool` | `true` | no |
| <a name="input_create_air_gapped_vault"></a> [create\_air\_gapped\_vault](#input\_create\_air\_gapped\_vault) | Determines whether a logically air-gapped vault is created | `bool` | `false` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Determines whether the IAM role assumed by AWS Backup is created. Set to `false` to use `iam_role_arn` | `bool` | `true` | no |
| <a name="input_create_iam_role_additional_policy"></a> [create\_iam\_role\_additional\_policy](#input\_create\_iam\_role\_additional\_policy) | Determines whether `iam_role_additional_policy_json` is attached inline to the IAM role | `bool` | `false` | no |
| <a name="input_create_vault"></a> [create\_vault](#input\_create\_vault) | Determines whether a backup vault is created. Set to `false` to target an existing vault through `existing_vault_name` | `bool` | `true` | no |
| <a name="input_existing_vault_name"></a> [existing\_vault\_name](#input\_existing\_vault\_name) | Name of an existing backup vault targeted by the plans and notifications when `create_vault` is `false` | `string` | `null` | no |
| <a name="input_iam_role_additional_policy_arns"></a> [iam\_role\_additional\_policy\_arns](#input\_iam\_role\_additional\_policy\_arns) | List of additional IAM policy ARNs attached to the IAM role, for example `AWSBackupServiceRolePolicyForItemRestores` | `list(string)` | `[]` | no |
| <a name="input_iam_role_additional_policy_json"></a> [iam\_role\_additional\_policy\_json](#input\_iam\_role\_additional\_policy\_json) | IAM policy document (JSON) attached inline to the IAM role when `create_iam_role_additional_policy` is `true`, for example KMS permissions on the keys of the protected resources | `string` | `null` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | ARN of an existing IAM role assumed by AWS Backup for the selections when `create_iam_role` is `false`. Can be overridden per plan | `string` | `null` | no |
| <a name="input_iam_role_attach_s3_policies"></a> [iam\_role\_attach\_s3\_policies](#input\_iam\_role\_attach\_s3\_policies) | Determines whether the AWS managed policies for S3 backup and restore are attached to the IAM role | `bool` | `true` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name of the IAM role. Defaults to `<name>-backup` | `string` | `null` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Path of the IAM role | `string` | `null` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of the policy used as the permissions boundary of the IAM role | `string` | `null` | no |
| <a name="input_plans"></a> [plans](#input\_plans) | Map of backup plans to create, keyed by plan name. Each plan has one or more `rules` and zero or more `selections`:<br/>- `name`: plan name, defaults to the map key<br/>- `windows_vss_enabled`: enable Windows VSS backup for EC2 instances<br/>- `iam_role_arn`: IAM role assumed by AWS Backup for the selections of this plan, defaults to the module role<br/>- `rules[]`: `name`, `schedule` (cron), `schedule_expression_timezone`, `start_window`, `completion_window`, `enable_continuous_backup`, `recovery_point_tags`, `target_logically_air_gapped_backup_vault_arn`, `lifecycle` (`cold_storage_after`, `delete_after`, `opt_in_to_archive_for_supported_resources`), `copy_actions[]` (`destination_vault_arn`, `lifecycle`)<br/>- `selections{}`: keyed by selection name: `name`, `resources`, `not_resources`, `selection_tags[]` (`type`, `key`, `value`), `conditions` (`string_equals[]`, `string_like[]`, `string_not_equals[]`, `string_not_like[]` of `key`/`value`) | <pre>map(object({<br/>    name                = optional(string)<br/>    windows_vss_enabled = optional(bool, false)<br/>    iam_role_arn        = optional(string)<br/>    rules = list(object({<br/>      name                                         = string<br/>      schedule                                     = optional(string)<br/>      schedule_expression_timezone                 = optional(string)<br/>      start_window                                 = optional(number)<br/>      completion_window                            = optional(number)<br/>      enable_continuous_backup                     = optional(bool)<br/>      recovery_point_tags                          = optional(map(string))<br/>      target_logically_air_gapped_backup_vault_arn = optional(string)<br/>      lifecycle = optional(object({<br/>        cold_storage_after                        = optional(number)<br/>        delete_after                              = optional(number)<br/>        opt_in_to_archive_for_supported_resources = optional(bool)<br/>      }))<br/>      copy_actions = optional(list(object({<br/>        destination_vault_arn = string<br/>        lifecycle = optional(object({<br/>          cold_storage_after                        = optional(number)<br/>          delete_after                              = optional(number)<br/>          opt_in_to_archive_for_supported_resources = optional(bool)<br/>        }))<br/>      })), [])<br/>    }))<br/>    selections = optional(map(object({<br/>      name          = optional(string)<br/>      resources     = optional(list(string))<br/>      not_resources = optional(list(string))<br/>      selection_tags = optional(list(object({<br/>        type  = string<br/>        key   = string<br/>        value = string<br/>      })), [])<br/>      conditions = optional(object({<br/>        string_equals     = optional(list(object({ key = string, value = string })), [])<br/>        string_like       = optional(list(object({ key = string, value = string })), [])<br/>        string_not_equals = optional(list(object({ key = string, value = string })), [])<br/>        string_not_like   = optional(list(object({ key = string, value = string })), [])<br/>      }))<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vault_copy_source_account_ids"></a> [vault\_copy\_source\_account\_ids](#input\_vault\_copy\_source\_account\_ids) | List of AWS account IDs allowed to copy recovery points into the backup vault (cross-account backup) | `list(string)` | `[]` | no |
| <a name="input_vault_force_destroy"></a> [vault\_force\_destroy](#input\_vault\_force\_destroy) | Determines whether all recovery points stored in the vault are deleted so that the vault can be destroyed without error | `bool` | `false` | no |
| <a name="input_vault_kms_key_arn"></a> [vault\_kms\_key\_arn](#input\_vault\_kms\_key\_arn) | ARN of the KMS key used to encrypt the backup vault. Defaults to the AWS managed key `aws/backup`. The key policy must allow AWS Backup to use the key | `string` | `null` | no |
| <a name="input_vault_lock_changeable_for_days"></a> [vault\_lock\_changeable\_for\_days](#input\_vault\_lock\_changeable\_for\_days) | The number of days before the lock date. When set, the vault lock is created in compliance mode and cannot be removed once the lock date is reached. Leave `null` for governance mode | `number` | `null` | no |
| <a name="input_vault_lock_enabled"></a> [vault\_lock\_enabled](#input\_vault\_lock\_enabled) | Determines whether a vault lock configuration is created on the backup vault | `bool` | `false` | no |
| <a name="input_vault_lock_max_retention_days"></a> [vault\_lock\_max\_retention\_days](#input\_vault\_lock\_max\_retention\_days) | The maximum retention period, in days, that the vault retains its recovery points | `number` | `null` | no |
| <a name="input_vault_lock_min_retention_days"></a> [vault\_lock\_min\_retention\_days](#input\_vault\_lock\_min\_retention\_days) | The minimum retention period, in days, that the vault retains its recovery points | `number` | `null` | no |
| <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name) | Name of the backup vault. Defaults to `name` | `string` | `null` | no |
| <a name="input_vault_notifications_enabled"></a> [vault\_notifications\_enabled](#input\_vault\_notifications\_enabled) | Determines whether the backup vault events are sent to `vault_notifications_sns_topic_arn` | `bool` | `false` | no |
| <a name="input_vault_notifications_events"></a> [vault\_notifications\_events](#input\_vault\_notifications\_events) | List of backup vault events sent to the SNS topic | `list(string)` | <pre>[<br/>  "BACKUP_JOB_FAILED",<br/>  "COPY_JOB_FAILED",<br/>  "RESTORE_JOB_FAILED"<br/>]</pre> | no |
| <a name="input_vault_notifications_sns_topic_arn"></a> [vault\_notifications\_sns\_topic\_arn](#input\_vault\_notifications\_sns\_topic\_arn) | ARN of the SNS topic that receives the backup vault events when `vault_notifications_enabled` is `true`. The topic policy must allow `backup.amazonaws.com` to publish | `string` | `null` | no |
| <a name="input_vault_policy"></a> [vault\_policy](#input\_vault\_policy) | IAM policy document (JSON) applied to the backup vault when `attach_vault_policy` is `true`. Merged with the statements generated from `vault_copy_source_account_ids` | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_air_gapped_vault_arn"></a> [air\_gapped\_vault\_arn](#output\_air\_gapped\_vault\_arn) | The ARN of the logically air-gapped vault |
| <a name="output_air_gapped_vault_id"></a> [air\_gapped\_vault\_id](#output\_air\_gapped\_vault\_id) | The name of the logically air-gapped vault |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role used by backup selections, created or provided |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | The name of the IAM role created by the module |
| <a name="output_plans"></a> [plans](#output\_plans) | Map of backup plans created, keyed by plan key, with `id`, `arn` and `version` |
| <a name="output_selections"></a> [selections](#output\_selections) | Map of backup selection IDs, keyed by `<plan key>/<selection key>` |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | The ARN of the backup vault |
| <a name="output_vault_id"></a> [vault\_id](#output\_vault\_id) | The name of the backup vault |
| <a name="output_vault_lock_configuration_id"></a> [vault\_lock\_configuration\_id](#output\_vault\_lock\_configuration\_id) | The name of the vault the lock configuration applies to |
| <a name="output_vault_name"></a> [vault\_name](#output\_vault\_name) | The name of the vault targeted by the backup plans, created or provided |
| <a name="output_vault_recovery_points"></a> [vault\_recovery\_points](#output\_vault\_recovery\_points) | The number of recovery points stored in the backup vault |
<!-- END_TF_DOCS -->

## Authors

Module is maintained by [Baptiste Gauduchon](https://github.com/bgauduch).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/bgauduch/terraform-aws-backup/tree/main/LICENSE) for full details.
