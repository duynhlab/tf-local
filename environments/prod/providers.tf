terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# Hybrid emulator routing (same for every regional provider alias):
#   floci      :4566 → iam, sts, s3, kms
#   ministack  :4567 → ec2 (advanced VPC), elbv2, wafv2
#
# See docs/support.md for the per-service support matrix.

locals {
  endpoints = {
    ec2   = "http://localhost:4567"
    elbv2 = "http://localhost:4567"
    wafv2 = "http://localhost:4567"
    iam   = "http://localhost:4566"
    sts   = "http://localhost:4566"
    s3    = "http://localhost:4566"
    kms   = "http://localhost:4566"
  }
}

# Default provider (modules without explicit alias)
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = local.endpoints.ec2
    elbv2 = local.endpoints.elbv2
    wafv2 = local.endpoints.wafv2
    iam   = local.endpoints.iam
    sts   = local.endpoints.sts
    s3    = local.endpoints.s3
    kms   = local.endpoints.kms
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# Region A — ap-southeast-1
provider "aws" {
  alias                       = "ap_southeast_1"
  region                      = "ap-southeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = local.endpoints.ec2
    elbv2 = local.endpoints.elbv2
    wafv2 = local.endpoints.wafv2
    iam   = local.endpoints.iam
    sts   = local.endpoints.sts
    s3    = local.endpoints.s3
    kms   = local.endpoints.kms
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# Region B — us-east-1
provider "aws" {
  alias                       = "us_east_1"
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = local.endpoints.ec2
    elbv2 = local.endpoints.elbv2
    wafv2 = local.endpoints.wafv2
    iam   = local.endpoints.iam
    sts   = local.endpoints.sts
    s3    = local.endpoints.s3
    kms   = local.endpoints.kms
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
