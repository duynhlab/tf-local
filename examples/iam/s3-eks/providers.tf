# EKS Pod → S3 (same account) — floci :4566; 12-digit access_key = account ID.

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = var.account_id
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    iam = local.lab_ministack_endpoints_iam_s3_sts.iam
    s3  = local.lab_ministack_endpoints_iam_s3_sts.s3
    sts = local.lab_ministack_endpoints_iam_s3_sts.sts
  }
}
