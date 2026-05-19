# ExternalDNS cross-account Route53 — ministack :4567.

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
  access_key                  = var.shared_services_account_id
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam     = local.lab_ministack_endpoints_route53.iam
    route53 = local.lab_ministack_endpoints_route53.route53
    sts     = local.lab_ministack_endpoints_route53.sts
  }
}

provider "aws" {
  alias                       = "shared_services"
  region                      = "us-east-1"
  access_key                  = var.shared_services_account_id
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam     = local.lab_ministack_endpoints_route53.iam
    route53 = local.lab_ministack_endpoints_route53.route53
    sts     = local.lab_ministack_endpoints_route53.sts
  }
}
