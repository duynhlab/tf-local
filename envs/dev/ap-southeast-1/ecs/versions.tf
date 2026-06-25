terraform {
  # >= 1.11 for S3 native state locking (use_lockfile, no DynamoDB).
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
