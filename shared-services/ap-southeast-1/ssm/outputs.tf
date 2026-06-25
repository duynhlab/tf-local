output "parameter_names" {
  description = "Names of the shared SSM parameters"
  value       = module.shared_config.parameter_names
}
