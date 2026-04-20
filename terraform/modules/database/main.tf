# ═══════════════════════════════════════════════════════════════
# DATABASE MODULE
# DynamoDB table for storing URL mappings
# ═══════════════════════════════════════════════════════════════

resource "aws_dynamodb_table" "url_mappings" {
  name         = "url-mappings"
  billing_mode = "PAY_PER_REQUEST"

  # Primary key — the short code e.g. "abc123"
  hash_key = "code"

  attribute {
    name = "code"
    type = "S"
  }

  tags = { Name = "${var.project_name}-url-mappings" }
}