# ---------------------------------------------------------------------------
# Providers — Production
# Team A (Account 222222222) SNS in us-west-2
# Team B (Account 444444444) SQS in us-west-2 (produs) + eu-north-1 (prodeu)
#
# Floci emulates all accounts/regions on localhost:4567
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

# Team B — us-west-2 (produs, default provider)
provider "aws" {
  region                      = "us-west-2"
  access_key                  = "test"
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

# Team B — eu-north-1 (prodeu)
provider "aws" {
  alias                       = "eu"
  region                      = "eu-north-1"
  access_key                  = "test"
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

# Team A — us-west-2 (SNS owner)
provider "aws" {
  alias                       = "team_a"
  region                      = "us-west-2"
  access_key                  = "test"
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
