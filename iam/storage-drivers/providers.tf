# EBS/EFS CSI driver IAM — ministack :4567 (ec2, iam, sts).

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
    ec2 = local.lab_ministack_endpoints_ec2_iam_sts.ec2
    iam = local.lab_ministack_endpoints_ec2_iam_sts.iam
    sts = local.lab_ministack_endpoints_ec2_iam_sts.sts
  }
}
