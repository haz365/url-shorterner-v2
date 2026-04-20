variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN to grant access to"
  type        = string
}