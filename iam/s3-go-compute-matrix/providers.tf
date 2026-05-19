# Go BE → S3 compute matrix — ministack :4567; 12-digit access_key = account ID.

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
  access_key                  = "888888888888"
  secret_key                  = local.lab_secret_key_test
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = local.lab_ministack_endpoints_iam_s3_sts.iam
    s3  = local.lab_ministack_endpoints_iam_s3_sts.s3
    sts = local.lab_ministack_endpoints_iam_s3_sts.sts
  }
}

provider "aws" {
  alias                       = "secondary"
  region                      = "us-east-1"
  access_key                  = "888888888888"
  secret_key                  = local.lab_secret_key_test
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = local.lab_ministack_endpoints_iam_s3_sts.iam
    s3  = local.lab_ministack_endpoints_iam_s3_sts.s3
    sts = local.lab_ministack_endpoints_iam_s3_sts.sts
  }
}

provider "aws" {
  alias                       = "data_account"
  region                      = "ap-southeast-1"
  access_key                  = "999999999998"
  secret_key                  = local.lab_secret_key_test
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = local.lab_ministack_endpoints_iam_s3_sts.iam
    s3  = local.lab_ministack_endpoints_iam_s3_sts.s3
    sts = local.lab_ministack_endpoints_iam_s3_sts.sts
  }
}
