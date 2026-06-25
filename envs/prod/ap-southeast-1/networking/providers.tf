# Real AWS — prod account, multi-region (same account, different regions).
# Local floci testing: AWS_ENDPOINT_URL + AWS_ACCESS_KEY_ID=333333333333 env vars.
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = { Project = var.project, Environment = var.environment, ManagedBy = "terraform", Component = "networking" }
  }
}

provider "aws" {
  alias  = "ap_southeast_1"
  region = "ap-southeast-1"
  default_tags {
    tags = { Project = var.project, Environment = var.environment, ManagedBy = "terraform", Component = "networking" }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = { Project = var.project, Environment = var.environment, ManagedBy = "terraform", Component = "networking" }
  }
}
