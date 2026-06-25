# Central log-archive bucket in shared-services. Other buckets point their
# aws_s3_bucket_logging at this bucket; ALB / CloudTrail deliver here too.
module "log_archive" {
  source = "../../../modules/data/s3-logs"

  bucket_name = "${var.project}-shared-logs"
  account_id  = local.lab_accounts.shared
  log_sources = ["s3", "alb", "cloudtrail"]

  tags = var.tags
}
