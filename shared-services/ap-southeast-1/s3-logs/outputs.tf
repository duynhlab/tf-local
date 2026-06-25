output "bucket_id" {
  description = "Name of the central log-archive bucket"
  value       = module.log_archive.bucket_id
}

output "bucket_arn" {
  description = "ARN of the central log-archive bucket (use as logging_target_bucket)"
  value       = module.log_archive.bucket_arn
}
