# Unit tests of the report sub-module with mocked providers, no AWS credentials needed.

mock_provider "aws" {}

variables {
  name           = "unit"
  s3_bucket_name = "unit-backup-reports"
}

run "defaults" {
  command = plan

  module {
    source = "./modules/report"
  }

  assert {
    condition     = length(aws_backup_report_plan.this) == 3
    error_message = "The three job report templates are expected by default."
  }

  assert {
    condition     = aws_backup_report_plan.this["BACKUP_JOB_REPORT"].name == "unit_backup_job_report"
    error_message = "Report plan names must be derived from the name and the template."
  }

  assert {
    condition     = one(aws_backup_report_plan.this["BACKUP_JOB_REPORT"].report_delivery_channel).s3_bucket_name == "unit-backup-reports" && length(one(aws_backup_report_plan.this["BACKUP_JOB_REPORT"].report_delivery_channel).formats) == 2
    error_message = "The delivery channel must target the given bucket with both formats."
  }

  assert {
    condition     = one(aws_backup_report_plan.this["BACKUP_JOB_REPORT"].report_setting).framework_arns == null
    error_message = "Job reports must not carry framework ARNs."
  }
}

run "create_false" {
  command = plan

  module {
    source = "./modules/report"
  }

  variables {
    create = false
  }

  assert {
    condition     = length(aws_backup_report_plan.this) == 0
    error_message = "`create = false` must disable every resource."
  }
}

run "compliance" {
  command = plan

  module {
    source = "./modules/report"
  }

  variables {
    name             = "unit-compliance"
    report_templates = ["RESOURCE_COMPLIANCE_REPORT"]
    framework_arns   = ["arn:aws:backup:eu-west-1:123456789012:framework:unit-12345678-1234-1234-1234-123456789012"]
    formats          = ["CSV"]
    s3_key_prefix    = "reports"
    descriptions     = { RESOURCE_COMPLIANCE_REPORT = "Resource compliance" }
  }

  assert {
    condition     = aws_backup_report_plan.this["RESOURCE_COMPLIANCE_REPORT"].name == "unit_compliance_resource_compliance_report" && aws_backup_report_plan.this["RESOURCE_COMPLIANCE_REPORT"].description == "Resource compliance"
    error_message = "Hyphens must be replaced and the description applied."
  }

  assert {
    condition     = length(one(aws_backup_report_plan.this["RESOURCE_COMPLIANCE_REPORT"].report_setting).framework_arns) == 1 && one(aws_backup_report_plan.this["RESOURCE_COMPLIANCE_REPORT"].report_setting).number_of_frameworks == 1
    error_message = "Compliance reports must carry the framework ARNs."
  }
}

run "invalid_name" {
  command = plan

  module {
    source = "./modules/report"
  }

  variables {
    name = "1unit"
  }

  expect_failures = [var.name]
}

run "invalid_template" {
  command = plan

  module {
    source = "./modules/report"
  }

  variables {
    report_templates = ["INVALID"]
  }

  expect_failures = [var.report_templates]
}

run "invalid_compliance_without_framework" {
  command = plan

  module {
    source = "./modules/report"
  }

  variables {
    report_templates = ["CONTROL_COMPLIANCE_REPORT"]
  }

  expect_failures = [var.report_templates]
}

run "invalid_bucket_name" {
  command = plan

  module {
    source = "./modules/report"
  }

  variables {
    s3_bucket_name = "Invalid_Bucket"
  }

  expect_failures = [var.s3_bucket_name]
}

run "invalid_format" {
  command = plan

  module {
    source = "./modules/report"
  }

  variables {
    formats = ["XML"]
  }

  expect_failures = [var.formats]
}
