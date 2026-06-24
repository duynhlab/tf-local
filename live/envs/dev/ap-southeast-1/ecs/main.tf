# Reads the dev networking stack's outputs (local state) — apply networking first.
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../networking/terraform.tfstate"
  }
}

module "service_sg" {
  source = "../../../../../modules/networking/security-group"

  name   = "${var.project}-dev-ecs"
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id

  ingress_rules = {
    http = {
      description = "HTTP from within the VPC"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = data.terraform_remote_state.networking.outputs.vpc_cidr
    }
  }

  tags = var.tags
}

module "ecs" {
  source = "../../../../../modules/compute/ecs-service"

  name               = "${var.project}-dev-app"
  subnet_ids         = data.terraform_remote_state.networking.outputs.app_subnet_ids
  security_group_ids = [module.service_sg.security_group_id]

  cpu           = "256"
  memory        = "512"
  desired_count = 1

  container_definitions = jsonencode([
    {
      name         = "app"
      image        = "public.ecr.aws/nginx/nginx:latest"
      essential    = true
      portMappings = [{ containerPort = 80, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project}-dev-app"
          "awslogs-region"        = "ap-southeast-1"
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = var.tags
}
