output "report_plans" {
  description = "Map of report plans keyed by template name, with `id`, `arn` and `deployment_status`"
  value = {
    for template, plan in aws_backup_report_plan.this : template => {
      id                = plan.id
      arn               = plan.arn
      deployment_status = plan.deployment_status
    }
  }
}
