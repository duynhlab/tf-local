output "role_arn" {
  description = "ARN of the IAM role."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.this.name
}

output "role_unique_id" {
  description = "Stable, unique string identifying the IAM role."
  value       = aws_iam_role.this.unique_id
}

output "policy_arn" {
  description = "ARN of the customer-managed policy created from inline_policy_json, or null when none was created."
  value       = local.create_policy ? aws_iam_policy.this[0].arn : null
}
