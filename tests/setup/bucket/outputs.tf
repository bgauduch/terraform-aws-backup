output "name" {
  description = "Name of the fixture bucket"
  value       = aws_s3_bucket.this.id
}
