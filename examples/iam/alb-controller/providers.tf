# AWS Load Balancer Controller on EKS — floci :4566 (ec2, elbv2, iam, sts).

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
    ec2   = local.lab_ministack_endpoints_alb.ec2
    elbv2 = local.lab_ministack_endpoints_alb.elbv2
    iam   = local.lab_ministack_endpoints_alb.iam
    sts   = local.lab_ministack_endpoints_alb.sts
  }
}
