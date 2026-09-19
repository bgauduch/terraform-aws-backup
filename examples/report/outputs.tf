output "report_plans" {
  description = "Map of report plans keyed by template name"
  value       = module.report.report_plans
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket receiving the reports"
  value       = aws_s3_bucket.reports.id
}
