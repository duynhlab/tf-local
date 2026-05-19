# Cross-account secrets/parameters — ministack :4567 (iam, sts).

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
  access_key                  = var.app_account_id
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = local.lab_ministack_endpoints_iam_sts.iam
    sts = local.lab_ministack_endpoints_iam_sts.sts
  }
}

provider "aws" {
  alias                       = "security_account"
  region                      = "ap-southeast-1"
  access_key                  = var.security_account_id
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = local.lab_ministack_endpoints_iam_sts.iam
    sts = local.lab_ministack_endpoints_iam_sts.sts
  }
}
