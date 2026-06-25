# Real AWS — shared-services account. Local floci testing via env vars
# (AWS_ENDPOINT_URL + AWS_ACCESS_KEY_ID=100000000000).
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = "shared"
      ManagedBy   = "terraform"
      Component   = "ecr"
    }
  }
}
