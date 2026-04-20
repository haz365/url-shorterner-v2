# ═══════════════════════════════════════════════════════════════
# ROOT MAIN.TF
# Wires all modules together
# ═══════════════════════════════════════════════════════════════

# ─── VPC ─────────────────────────────────────────────────────
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

# ─── ECR ─────────────────────────────────────────────────────
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

# ─── DATABASE ────────────────────────────────────────────────
module "database" {
  source       = "./modules/database"
  project_name = var.project_name
}

# ─── IAM ─────────────────────────────────────────────────────
module "iam" {
  source             = "./modules/iam"
  project_name       = var.project_name
  dynamodb_table_arn = module.database.table_arn
}

# ─── SECURITY ────────────────────────────────────────────────
module "security" {
  source         = "./modules/security"
  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port
}

# ─── ALB ─────────────────────────────────────────────────────
module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  container_port    = var.container_port
}

# ─── ECS ─────────────────────────────────────────────────────
module "ecs" {
  source                  = "./modules/ecs"
  project_name            = var.project_name
  region                  = var.region
  container_port          = var.container_port
  desired_count           = var.desired_count
  ecr_repository_url      = module.ecr.repository_url
  private_subnet_id       = module.vpc.private_subnet_id
  ecs_sg_id               = module.security.ecs_sg_id
  target_group_arn        = module.alb.target_group_arn
  alb_listener_arn        = module.alb.http_listener_arn
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn
  dynamodb_table_name     = module.database.table_name
}

# ─── GITHUB ACTIONS ──────────────────────────────────────────
module "github_actions" {
  source             = "./modules/github-actions"
  project_name       = var.project_name
  github_org         = var.github_org
  github_repo        = var.github_repo
  ecr_repository_arn = module.ecr.repository_arn
  ecs_cluster_name   = module.ecs.cluster_name
  ecs_service_name   = module.ecs.service_name
}