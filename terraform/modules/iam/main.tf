# ═══════════════════════════════════════════════════════════════
# IAM MODULE
# Two roles for ECS Fargate:
# 1. Task Execution Role — ECS uses this to START containers
# 2. Task Role — your APP CODE uses this at runtime
# ═══════════════════════════════════════════════════════════════

# ─── Task Execution Role ──────────────────────────────────────
resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─── Task Role ────────────────────────────────────────────────
resource "aws_iam_role" "task" {
  name = "${var.project_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Allow app to read and write URL mappings in DynamoDB
resource "aws_iam_role_policy" "task_dynamodb" {
  name = "${var.project_name}-task-dynamodb-policy"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",    # Store new URL mapping
        "dynamodb:GetItem",    # Look up a short code
        "dynamodb:UpdateItem"  # Increment visit counter
      ]
      Resource = var.dynamodb_table_arn
    }]
  })
}