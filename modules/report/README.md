# AWS Backup Report Submodule

Terraform submodule which creates one report plan per template, delivered to an existing S3 bucket. The bucket policy must allow the service-linked role `AWSServiceRoleForBackupReports` to put objects; see the [report example](https://github.com/bgauduch/terraform-aws-backup/tree/main/examples/report). Compliance templates require `framework_arns`.

## Usage

```hcl
module "report" {
  source = "bgauduch/backup/aws//modules/report"

  name           = "application"
  s3_bucket_name = "application-backup-reports"

  report_templates = ["BACKUP_JOB_REPORT", "RESTORE_JOB_REPORT"]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_report_plan.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_report_plan) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accounts"></a> [accounts](#input\_accounts) | List of AWS account IDs covered by the reports. Defaults to the current account | `list(string)` | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | Determines whether resources will be created (affects all resources) | `bool` | `true` | no |
| <a name="input_descriptions"></a> [descriptions](#input\_descriptions) | Map of report plan descriptions keyed by template name | `map(string)` | `{}` | no |
| <a name="input_formats"></a> [formats](#input\_formats) | Set of report formats. Valid values: `CSV`, `JSON` | `set(string)` | <pre>[<br/>  "CSV",<br/>  "JSON"<br/>]</pre> | no |
| <a name="input_framework_arns"></a> [framework\_arns](#input\_framework\_arns) | List of AWS Backup Audit Manager framework ARNs covered by the compliance reports | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix of the report plans. Hyphens are replaced by underscores and the lowercased template name is appended | `string` | n/a | yes |
| <a name="input_organization_units"></a> [organization\_units](#input\_organization\_units) | List of AWS Organizations organizational unit IDs covered by the reports | `list(string)` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | List of AWS regions covered by the reports. Defaults to the current region | `list(string)` | `null` | no |
| <a name="input_report_templates"></a> [report\_templates](#input\_report\_templates) | Set of report templates to create a report plan for. Valid values: `BACKUP_JOB_REPORT`, `COPY_JOB_REPORT`, `RESTORE_JOB_REPORT`, `RESOURCE_COMPLIANCE_REPORT`, `CONTROL_COMPLIANCE_REPORT` | `set(string)` | <pre>[<br/>  "BACKUP_JOB_REPORT",<br/>  "COPY_JOB_REPORT",<br/>  "RESTORE_JOB_REPORT"<br/>]</pre> | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the S3 bucket that receives the reports. The bucket policy must allow `AWSServiceRoleForBackupReports` to put objects | `string` | n/a | yes |
| <a name="input_s3_key_prefix"></a> [s3\_key\_prefix](#input\_s3\_key\_prefix) | Prefix under which the reports are delivered in the S3 bucket | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_report_plans"></a> [report\_plans](#output\_report\_plans) | Map of report plans keyed by template name, with `id`, `arn` and `deployment_status` |
<!-- END_TF_DOCS -->
