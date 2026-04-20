# ═══════════════════════════════════════════════════════════════
# ROOT OUTPUTS
# Printed after terraform apply finishes
# ═══════════════════════════════════════════════════════════════

output "app_url" {
  description = "Your URL shortener — open this in your browser!"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "ECR URL — use when pushing Docker images"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "cloudwatch_log_group" {
  description = "View container logs here"
  value       = module.ecs.log_group_name
}