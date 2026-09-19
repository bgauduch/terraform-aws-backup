# Cross-region copy

Configuration in this directory creates a primary backup vault and plan in one region and a secondary vault in another region. The daily rule copies every recovery point to the secondary vault through a copy action.

For cross-account copies, add the source account ID to `vault_copy_source_account_ids` on the destination vault module.

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
| <a name="module_backup_secondary"></a> [backup\_secondary](#module\_backup\_secondary) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_table_arn"></a> [dynamodb\_table\_arn](#output\_dynamodb\_table\_arn) | The ARN of the DynamoDB table protected by the backup plan |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role used by backup selections |
| <a name="output_plans"></a> [plans](#output\_plans) | Map of backup plans created |
| <a name="output_secondary_vault_arn"></a> [secondary\_vault\_arn](#output\_secondary\_vault\_arn) | The ARN of the secondary backup vault receiving the copies |
| <a name="output_secondary_vault_name"></a> [secondary\_vault\_name](#output\_secondary\_vault\_name) | The name of the secondary backup vault receiving the copies |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | The ARN of the primary backup vault |
| <a name="output_vault_name"></a> [vault\_name](#output\_vault\_name) | The name of the primary backup vault |
<!-- END_TF_DOCS -->
