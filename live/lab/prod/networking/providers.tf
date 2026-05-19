terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# Hybrid: floci :4566 + ministack :4567 — see modules/lab-provider/common.tf

provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = local.lab_access_key_test
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = local.lab_hybrid_endpoints.ec2
    elbv2 = local.lab_hybrid_endpoints.elbv2
    wafv2 = local.lab_hybrid_endpoints.wafv2
    iam   = local.lab_hybrid_endpoints.iam
    sts   = local.lab_hybrid_endpoints.sts
    s3    = local.lab_hybrid_endpoints.s3
    kms   = local.lab_hybrid_endpoints.kms
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias                       = "ap_southeast_1"
  region                      = "ap-southeast-1"
  access_key                  = local.lab_access_key_test
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = local.lab_hybrid_endpoints.ec2
    elbv2 = local.lab_hybrid_endpoints.elbv2
    wafv2 = local.lab_hybrid_endpoints.wafv2
    iam   = local.lab_hybrid_endpoints.iam
    sts   = local.lab_hybrid_endpoints.sts
    s3    = local.lab_hybrid_endpoints.s3
    kms   = local.lab_hybrid_endpoints.kms
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias                       = "us_east_1"
  region                      = "us-east-1"
  access_key                  = local.lab_access_key_test
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2   = local.lab_hybrid_endpoints.ec2
    elbv2 = local.lab_hybrid_endpoints.elbv2
    wafv2 = local.lab_hybrid_endpoints.wafv2
    iam   = local.lab_hybrid_endpoints.iam
    sts   = local.lab_hybrid_endpoints.sts
    s3    = local.lab_hybrid_endpoints.s3
    kms   = local.lab_hybrid_endpoints.kms
  }

  default_tags {
    tags = {
      Project     = "vpc-connectivity-lab"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
