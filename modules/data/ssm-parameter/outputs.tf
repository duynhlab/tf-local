output "parameter_arns" {
  description = "Map of parameter name => ARN for every created SSM parameter."
  value       = { for k, p in aws_ssm_parameter.this : k => p.arn }
}

output "parameter_names" {
  description = "List of created SSM parameter names."
  value       = keys(aws_ssm_parameter.this)
}
