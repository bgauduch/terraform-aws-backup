# Restore testing

Configuration in this directory creates a backup vault and plan protecting a DynamoDB table, and a weekly restore testing plan that restores the latest recovery point of the tagged tables and deletes the restored copy after one hour.

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
| <a name="module_restore_testing"></a> [restore\_testing](#module\_restore\_testing) | ../../modules/restore-testing | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role used by backup selections and restore tests |
| <a name="output_restore_testing_plan_arn"></a> [restore\_testing\_plan\_arn](#output\_restore\_testing\_plan\_arn) | The ARN of the restore testing plan |
| <a name="output_restore_testing_plan_name"></a> [restore\_testing\_plan\_name](#output\_restore\_testing\_plan\_name) | The name of the restore testing plan |
| <a name="output_restore_testing_selection_names"></a> [restore\_testing\_selection\_names](#output\_restore\_testing\_selection\_names) | Map of restore testing selection names |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | The ARN of the backup vault |
<!-- END_TF_DOCS -->
