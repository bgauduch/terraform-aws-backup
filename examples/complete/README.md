# Complete AWS Backup

Configuration in this directory creates:

- a backup vault encrypted with a customer managed KMS key, locked in governance mode, allowing cross-account copies from the current account, with failure notifications sent to an SNS topic
- a logically air-gapped vault
- the IAM role assumed by AWS Backup, extended with item-level restore and KMS permissions
- a backup plan with a daily and a monthly rule, selecting resources by tag and by ARN with conditions
- a DynamoDB table protected by the plan, used by the end-to-end backup and restore test

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

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
| <a name="module_backup"></a> [backup](#module\_backup) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_kms_alias.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_sns_topic.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.role_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vault_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_air_gapped_vault_arn"></a> [air\_gapped\_vault\_arn](#output\_air\_gapped\_vault\_arn) | The ARN of the logically air-gapped vault |
| <a name="output_dynamodb_table_arn"></a> [dynamodb\_table\_arn](#output\_dynamodb\_table\_arn) | The ARN of the DynamoDB table protected by the backup plan |
| <a name="output_dynamodb_table_name"></a> [dynamodb\_table\_name](#output\_dynamodb\_table\_name) | The name of the DynamoDB table protected by the backup plan |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role used by backup selections |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the KMS key encrypting the vault |
| <a name="output_plans"></a> [plans](#output\_plans) | Map of backup plans created |
| <a name="output_selections"></a> [selections](#output\_selections) | Map of backup selection IDs |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | The ARN of the SNS topic receiving the vault notifications |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | The ARN of the backup vault |
| <a name="output_vault_lock_configuration_id"></a> [vault\_lock\_configuration\_id](#output\_vault\_lock\_configuration\_id) | The name of the vault the lock configuration applies to |
| <a name="output_vault_name"></a> [vault\_name](#output\_vault\_name) | The name of the backup vault |
<!-- END_TF_DOCS -->
