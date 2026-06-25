variable "project" {
  description = "Project short slug used as resource name prefix"
  type        = string
  default     = "dnl"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "state_bucket" {
  description = "S3 bucket holding the networking stack state (for terraform_remote_state)"
  type        = string
}

variable "remote_state_config" {
  description = "Extra terraform_remote_state s3 config (leave {} for real AWS; floci sets endpoints/use_path_style/creds)"
  type        = any
  default     = {}
}

variable "app_port" {
  description = "Container/app listener port (Harley Spring app uses 8080)"
  type        = number
  default     = 8080
}

variable "container_image" {
  description = "Container image for the app task. Replace with your ECR image; must listen on app_port."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Fargate task memory (MiB)"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of running tasks"
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Common tags merged onto resources"
  type        = map(string)
  default     = {}
}
