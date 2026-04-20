output "table_arn" {
  description = "DynamoDB table ARN for IAM permissions"
  value       = aws_dynamodb_table.url_mappings.arn
}

output "table_name" {
  description = "DynamoDB table name passed to ECS as env var"
  value       = aws_dynamodb_table.url_mappings.name
}