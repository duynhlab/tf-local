output "role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.this.name
}

output "policy_arn" {
  description = "Inline policy ARN when created"
  value       = try(aws_iam_policy.this[0].arn, null)
}
