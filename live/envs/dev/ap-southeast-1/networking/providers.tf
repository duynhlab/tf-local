# Real AWS provider. No emulator config in code — when copied to a real account
# it works as-is. For local floci testing, set environment variables instead:
#   AWS_ENDPOINT_URL=http://localhost:4566 AWS_ACCESS_KEY_ID=111111111111 \
#   AWS_SECRET_ACCESS_KEY=test AWS_REGION=ap-southeast-1
# (the AWS provider routes all services to AWS_ENDPOINT_URL).
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "networking"
    }
  }
}
