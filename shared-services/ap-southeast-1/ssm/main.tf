# Shared config parameters (cross-account readers assume a role granting
# ssm:GetParameter* + kms:Decrypt — see docs/enterprise-roadmap.md).
module "shared_config" {
  source = "../../../modules/data/ssm-parameter"

  parameters = {
    "/shared/config/region" = {
      value       = "ap-southeast-1"
      description = "Default region for ${var.project}"
    }
    "/shared/config/log_bucket" = {
      value       = "${var.project}-shared-logs"
      description = "Central log-archive bucket name"
    }
  }

  tags = var.tags
}
