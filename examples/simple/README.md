# Simple AWS Backup

Configuration in this directory creates a backup vault encrypted with the AWS managed key, the IAM role assumed by AWS Backup and a daily backup plan selecting resources by tag.

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

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_backup"></a> [backup](#module\_backup) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role used by backup selections |
| <a name="output_plans"></a> [plans](#output\_plans) | Map of backup plans created |
| <a name="output_selections"></a> [selections](#output\_selections) | Map of backup selection IDs |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | The ARN of the backup vault |
| <a name="output_vault_name"></a> [vault\_name](#output\_vault\_name) | The name of the backup vault |
<!-- END_TF_DOCS -->
