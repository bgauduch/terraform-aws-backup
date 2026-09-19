output "name" {
  description = "Name of the fixture vault"
  value       = aws_backup_vault.this.name
}

output "arn" {
  description = "ARN of the fixture vault"
  value       = aws_backup_vault.this.arn
}
