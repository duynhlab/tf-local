output "key_arn" {
  description = "ARN of the shared CMK"
  value       = module.shared_kms.key_arn
}

output "key_id" {
  description = "ID of the shared CMK"
  value       = module.shared_kms.key_id
}

output "alias_name" {
  description = "Alias of the shared CMK"
  value       = module.shared_kms.alias_name
}
