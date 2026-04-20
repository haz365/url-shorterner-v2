# ═══════════════════════════════════════════════════════════════
# ALB MODULE
# Load balancer — HTTP only (no HTTPS, no Route 53)
# Users access the app via the ALB DNS name directly
# ═══════════════════════════════════════════════════════════════

# ─── Application Load Balancer ────────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]

  enable_deletion_protection = false

  tags = { Name = "${var.project_name}-alb" }
}

# ─── Target Group ─────────────────────────────────────────────
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = { Name = "${var.project_name}-tg" }
}

# ─── HTTP Listener ────────────────────────────────────────────
# Forwards traffic directly to ECS containers
# No HTTPS redirect needed — simpler setup
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = { Name = "${var.project_name}-http-listener" }
}