output "role_arn" {
  description = "Pod Identity role ARN bound to the app service account"
  value       = module.pod_identity.role_arn
}

output "bucket_arn" {
  description = "Demo app bucket ARN"
  value       = module.app_bucket.bucket_arn
}
