output "bucket_id" {
  description = "Name (ID) of the log-archive S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the log-archive S3 bucket. Pass as logging_target_bucket to other buckets."
  value       = aws_s3_bucket.this.arn
}
