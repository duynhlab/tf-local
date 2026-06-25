output "role_arn" {
  description = "ARN of the IAM role assumed by pods via Pod Identity."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.this.name
}

output "association_ids" {
  description = "Map of association label to its Pod Identity association ID."
  value       = { for k, a in aws_eks_pod_identity_association.this : k => a.association_id }
}
