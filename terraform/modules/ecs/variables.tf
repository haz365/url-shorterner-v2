variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "container_port" {
  type = number
}

variable "desired_count" {
  type = number
}

variable "ecr_repository_url" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "ecs_sg_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "alb_listener_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}