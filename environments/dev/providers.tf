terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# Hybrid emulator routing:
#   floci      :4566 → iam, sts, s3, kms
#   ministack  :4567 → ec2 (advanced VPC), elbv2, wafv2
#
# See docs/support.md for the per-service support matrix.
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = "http://localhost:4567"
    elbv2 = "http://localhost:4567"
    wafv2 = "http://localhost:4567"
    iam   = "http://localhost:4566"
    sts   = "http://localhost:4566"
    s3    = "http://localhost:4566"
    kms   = "http://localhost:4566"
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
