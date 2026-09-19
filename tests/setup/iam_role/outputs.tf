output "arn" {
  description = "ARN of the fixture role"
  value       = aws_iam_role.this.arn
}
