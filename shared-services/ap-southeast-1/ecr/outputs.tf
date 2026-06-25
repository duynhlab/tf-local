output "repository_urls" {
  description = "Map of repo short name to repository URL"
  value       = { for k, m in module.ecr : k => m.repository_url }
}

output "repository_arns" {
  description = "Map of repo short name to repository ARN"
  value       = { for k, m in module.ecr : k => m.repository_arn }
}
