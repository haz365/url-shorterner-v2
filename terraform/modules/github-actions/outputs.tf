output "role_arn" {
  description = "Role ARN to use in GitHub Actions workflow"
  value       = aws_iam_role.github_actions.arn
}