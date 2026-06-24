locals {
  name_prefix = "${var.project}-${var.environment}"
}

# Networking stack outputs (vpc, subnets, SGs) via remote state.
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = merge({
    bucket = var.state_bucket
    key    = "dev/ap-southeast-1/networking/terraform.tfstate"
    region = var.aws_region
  }, var.remote_state_config)
}

# App image registry.
module "ecr" {
  source = "../../../../../modules/compute/ecr"

  name         = "${local.name_prefix}/app"
  scan_on_push = true
  tags         = var.tags
}

# Public ALB -> forwards to the ECS service.
module "alb" {
  source = "../../../../../modules/networking/alb"

  name              = "${local.name_prefix}-alb"
  target_group_name = "${local.name_prefix}-tg"
  vpc_id            = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids        = data.terraform_remote_state.networking.outputs.public_subnet_ids
  security_group_ids = [
    data.terraform_remote_state.networking.outputs.alb_security_group_id,
  ]
  target_port       = var.app_port
  listener_port     = 80
  health_check_path = var.health_check_path

  tags = var.tags
}

# ECS Fargate service in the private app subnets, registered to the ALB.
module "ecs" {
  source = "../../../../../modules/compute/ecs-service"

  name       = "${local.name_prefix}-app"
  subnet_ids = data.terraform_remote_state.networking.outputs.app_subnet_ids
  security_group_ids = [
    data.terraform_remote_state.networking.outputs.ecs_security_group_id,
  ]

  cpu           = var.cpu
  memory        = var.memory
  desired_count = var.desired_count

  target_group_arn = module.alb.target_group_arn
  container_name   = "app"
  container_port   = var.app_port

  container_definitions = jsonencode([
    {
      name         = "app"
      image        = var.container_image
      essential    = true
      portMappings = [{ containerPort = var.app_port, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.name_prefix}-app"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = var.tags
}
