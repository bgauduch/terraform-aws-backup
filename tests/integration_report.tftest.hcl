# Integration tests of the report sub-module against a real AWS account. Every run is destroyed by the test framework.

provider "aws" {
  region = "eu-west-1"
}

run "setup" {
  module {
    source = "./tests/setup/random"
  }
}

run "bucket" {
  module {
    source = "./tests/setup/bucket"
  }

  variables {
    name = "it-${run.setup.id}-reports"
  }
}

run "report" {
  module {
    source = "./modules/report"
  }

  variables {
    name           = "it-${run.setup.id}"
    s3_bucket_name = run.bucket.name
    s3_key_prefix  = "backup"
  }

  assert {
    condition     = length(aws_backup_report_plan.this) == 3 && alltrue([for plan in aws_backup_report_plan.this : one(plan.report_delivery_channel).s3_bucket_name == run.bucket.name])
    error_message = "The three report plans must deliver to the bucket."
  }

  assert {
    condition     = alltrue([for plan in aws_backup_report_plan.this : can(regex("^arn:aws:backup:eu-west-1:[0-9]{12}:report-plan:", plan.arn))])
    error_message = "Report plan ARNs are expected."
  }
}
