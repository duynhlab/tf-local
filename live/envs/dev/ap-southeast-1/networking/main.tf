locals {
  name_prefix = "${var.project}-${var.environment}"
}

# 3-tier VPC: public (ALB/NAT) + private app (ECS) + private data (RDS).
module "vpc" {
  source = "../../../../../modules/networking/vpc"

  vpc_name          = local.name_prefix
  vpc_cidr          = var.vpc_cidr
  public_subnets    = var.public_subnets
  app_subnets       = var.app_subnets
  data_subnets      = var.data_subnets
  nat_gateway_count = var.nat_gateway_count

  # Gateway endpoint keeps S3/ECR-layer pulls off the NAT path (cost).
  # Default true for real AWS; set false on floci (CreateVpcEndpoint response
  # is not provider-parseable on floci — see docs/floci-unsupported.md).
  enable_s3_gateway_endpoint = var.enable_s3_gateway_endpoint

  tags = var.tags
}

# ALB SG — public ingress from the internet.
module "alb_sg" {
  source = "../../../../../modules/networking/security-group"

  name   = "${local.name_prefix}-alb"
  vpc_id = module.vpc.vpc_id

  ingress_rules = {
    http = {
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      description = "HTTPS from internet"
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  tags = var.tags
}

# ECS task SG — only the ALB may reach the app port.
module "ecs_sg" {
  source = "../../../../../modules/networking/security-group"

  name   = "${local.name_prefix}-ecs"
  vpc_id = module.vpc.vpc_id

  ingress_rules = {
    from_alb = {
      description                  = "App port from ALB only"
      from_port                    = var.app_port
      to_port                      = var.app_port
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.alb_sg.security_group_id
    }
  }

  tags = var.tags
}

# Database SG — only ECS tasks may reach the DB port.
module "db_sg" {
  source = "../../../../../modules/networking/security-group"

  name   = "${local.name_prefix}-db"
  vpc_id = module.vpc.vpc_id

  ingress_rules = {
    from_ecs = {
      description                  = "DB port from ECS only"
      from_port                    = var.db_port
      to_port                      = var.db_port
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.ecs_sg.security_group_id
    }
  }

  tags = var.tags
}
