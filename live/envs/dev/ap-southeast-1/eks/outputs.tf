output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "app_role_arn" {
  description = "Pod Identity role ARN for the app service account"
  value       = module.app_pod_identity.role_arn
}
