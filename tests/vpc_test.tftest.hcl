# Plan-only smoke test for networking/vpc module.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = [
        "ap-southeast-1a",
        "ap-southeast-1b",
        "ap-southeast-1c",
      ]
    }
  }
}

run "vpc_plan_smoke" {
  command = plan

  module {
    source = "../modules/networking/vpc"
  }

  variables {
    vpc_name       = "test-vpc"
    vpc_cidr       = "10.198.0.0/16"
    public_subnets = ["10.198.1.0/24", "10.198.2.0/24"]
    app_subnets    = ["10.198.11.0/24", "10.198.12.0/24"]
    data_subnets   = ["10.198.21.0/24", "10.198.22.0/24"]
    tags           = { Project = "test" }
  }
}
