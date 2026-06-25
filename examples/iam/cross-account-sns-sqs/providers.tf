terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0" }
  }
}

# Real AWS. Cross-account uses assume_role per account.
# floci note: floci isolates accounts by access key, not assume_role, so
# multi-account examples are validate/plan-only on floci.
provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = "dnl", ManagedBy = "terraform" } }
}

provider "aws" {
  alias  = "eu"
  region = var.eu_region
  assume_role { role_arn = var.eu_role_arn }
  default_tags { tags = { Project = "dnl", ManagedBy = "terraform" } }
}

provider "aws" {
  alias  = "team_a"
  region = var.team_a_region
  assume_role { role_arn = var.team_a_role_arn }
  default_tags { tags = { Project = "dnl", ManagedBy = "terraform" } }
}
