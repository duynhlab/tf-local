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

variable "vpc_cidr" {
  description = "VPC CIDR (see docs/subnet.csv)"
  type        = string
  default     = "10.100.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDRs (ALB / NAT), 1 per AZ"
  type        = list(string)
  default     = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
}

variable "app_subnets" {
  description = "Private app subnet CIDRs (ECS tasks), 1 per AZ"
  type        = list(string)
  default     = ["10.100.11.0/24", "10.100.12.0/24", "10.100.13.0/24"]
}

variable "data_subnets" {
  description = "Private database subnet CIDRs (RDS), 1 per AZ"
  type        = list(string)
  default     = ["10.100.21.0/24", "10.100.22.0/24", "10.100.23.0/24"]
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways (1 = cost-saving for dev, 3 = HA)"
  type        = number
  default     = 1
}

variable "enable_s3_gateway_endpoint" {
  description = "Create the S3 Gateway VPC endpoint (true on real AWS; false on floci — see docs/floci-unsupported.md)"
  type        = bool
  default     = true
}

variable "app_port" {
  description = "Container/app listener port the ALB forwards to"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port allowed from the ECS tier"
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Common tags merged onto resources"
  type        = map(string)
  default     = {}
}
