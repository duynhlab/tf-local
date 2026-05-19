# EKS cluster access entries — ministack :4567 (eks, iam, sts).

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

  endpoints {
    eks = local.lab_ministack_endpoints_eks.eks
    iam = local.lab_ministack_endpoints_eks.iam
    sts = local.lab_ministack_endpoints_eks.sts
  }
}
