terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# floci :4566 — shared-services account (100000000000)
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = local.lab_accounts.shared
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    kms = local.lab_floci_base
    iam = local.lab_floci_base
    sts = local.lab_floci_base
  }

  default_tags {
    tags = {
      Project     = var.project
      Environment = "shared"
      ManagedBy   = "terraform"
      Component   = "kms"
    }
  }
}
