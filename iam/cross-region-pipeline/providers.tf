# ---------------------------------------------------------------------------
# Providers — Cross-Region SNS→SQS Pipeline + EKS
# Account 111111111100, ap-southeast-1 (producer) + us-west-2 (consumer DR)
#
# Floci emulates all regions on localhost:4567
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# Producer region — SNS topic + SQS primary consumer
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                  = "111111111100"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    iam = "http://localhost:4567"
    s3  = "http://localhost:4567"
    sns = "http://localhost:4567"
    sqs = "http://localhost:4567"
    sts = "http://localhost:4567"
  }
}

# Consumer DR region — SQS replica consumer
provider "aws" {
  alias                       = "dr"
  region                      = "us-west-2"
  access_key                  = "111111111100"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4567"
    sns = "http://localhost:4567"
    sqs = "http://localhost:4567"
    sts = "http://localhost:4567"
  }
}
