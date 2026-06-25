output "vpc_id" {
  description = "Dev VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "Dev VPC CIDR"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB)"
  value       = module.vpc.public_subnet_ids
}

output "app_subnet_ids" {
  description = "Private app subnet IDs (ECS tasks)"
  value       = module.vpc.app_subnet_ids
}

output "data_subnet_ids" {
  description = "Private database subnet IDs (RDS)"
  value       = module.vpc.data_subnet_ids
}

output "alb_security_group_id" {
  description = "Security group for the ALB"
  value       = module.alb_sg.security_group_id
}

output "ecs_security_group_id" {
  description = "Security group for ECS tasks"
  value       = module.ecs_sg.security_group_id
}

output "db_security_group_id" {
  description = "Security group for the database tier"
  value       = module.db_sg.security_group_id
}
