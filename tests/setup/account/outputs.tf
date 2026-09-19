output "id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
