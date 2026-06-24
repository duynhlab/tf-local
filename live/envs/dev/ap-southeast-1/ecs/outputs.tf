output "cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "security_group_id" {
  description = "Service security group ID"
  value       = module.service_sg.security_group_id
}
