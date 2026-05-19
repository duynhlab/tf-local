output "bucket_arn" {
  description = "Training data bucket ARN"
  value       = aws_s3_bucket.training_data.arn
}

output "bucket_name" {
  description = "Training data bucket name"
  value       = aws_s3_bucket.training_data.id
}

output "irsa_role_arn" {
  description = "IRSA role ARN for ServiceAccount annotation"
  value       = module.s3_reader_irsa.role_arn
}

output "irsa_role_name" {
  description = "IRSA role name"
  value       = module.s3_reader_irsa.role_name
}

output "pod_identity_role_arn" {
  description = "Pod Identity role ARN"
  value       = module.s3_reader_pod_identity.role_arn
}

output "pod_identity_role_name" {
  description = "Pod Identity role name"
  value       = module.s3_reader_pod_identity.role_name
}

output "eks_service_account_annotation" {
  description = "Annotation for Kubernetes ServiceAccount (IRSA)"
  value       = "eks.amazonaws.com/role-arn: ${module.s3_reader_irsa.role_arn}"
}
