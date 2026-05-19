# Cross-region SNS/SQS pipeline — ministack :4567.

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
  access_key                  = "111111111100"
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = local.lab_ministack_endpoints_s3_events.iam
    s3  = local.lab_ministack_endpoints_s3_events.s3
    sns = local.lab_ministack_endpoints_s3_events.sns
    sqs = local.lab_ministack_endpoints_s3_events.sqs
    sts = local.lab_ministack_endpoints_s3_events.sts
  }
}

provider "aws" {
  alias                       = "dr"
  region                      = "us-west-2"
  access_key                  = "111111111100"
  secret_key                  = local.lab_secret_key_test
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = local.lab_ministack_endpoints_messaging.iam
    sns = local.lab_ministack_endpoints_messaging.sns
    sqs = local.lab_ministack_endpoints_messaging.sqs
    sts = local.lab_ministack_endpoints_messaging.sts
  }
}
