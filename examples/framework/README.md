# Audit Manager framework

Configuration in this directory creates a backup vault and plan protecting a DynamoDB table, and an AWS Backup Audit Manager framework evaluating five controls against them.

AWS Backup Audit Manager requires an active AWS Config recorder in the region. Set `enable_config_recorder = true` when the region has no recorder: the example then creates one, limited to the resource types the controls evaluate, together with its delivery bucket and role.

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
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.24 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.24 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_backup"></a> [backup](#module\_backup) | ../.. | n/a |
| <a name="module_framework"></a> [framework](#module\_framework) | ../../modules/framework | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_config_configuration_recorder.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_role.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.config_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.config_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_enable_config_recorder"></a> [enable\_config\_recorder](#input\_enable\_config\_recorder) | Determines whether an AWS Config recorder, delivery bucket and role are created. Set to `true` only when the region has no recorder yet | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_config_recorder_name"></a> [config\_recorder\_name](#output\_config\_recorder\_name) | The name of the AWS Config recorder created by the example, if any |
| <a name="output_framework_arn"></a> [framework\_arn](#output\_framework\_arn) | The ARN of the framework |
| <a name="output_framework_deployment_status"></a> [framework\_deployment\_status](#output\_framework\_deployment\_status) | The deployment status of the framework |
| <a name="output_framework_id"></a> [framework\_id](#output\_framework\_id) | The name of the framework |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | The ARN of the backup vault |
<!-- END_TF_DOCS -->
