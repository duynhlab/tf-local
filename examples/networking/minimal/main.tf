module "vpc" {
  source = "../../../modules/networking/vpc"

  vpc_name       = "example-minimal-vpc"
  vpc_cidr       = "10.199.0.0/16"
  public_subnets = ["10.199.1.0/24", "10.199.2.0/24"]
  app_subnets    = ["10.199.11.0/24", "10.199.12.0/24"]
  data_subnets   = ["10.199.21.0/24", "10.199.22.0/24"]

  tags = {
    Project = "vpc-connectivity-lab"
  }
}
