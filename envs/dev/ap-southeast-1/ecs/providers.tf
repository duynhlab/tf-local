# Real AWS provider — works as-is when copied to a real account.
# Local floci testing uses env vars only (AWS_ENDPOINT_URL + test creds).
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "ecs"
    }
  }
}
