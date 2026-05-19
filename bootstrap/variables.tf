variable "aws_region" {
  description = "Region for the state bucket"
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  type    = string
  default = "vpc-connectivity-lab"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state"
  type        = string
}

variable "state_kms_key_arn" {
  description = "Optional KMS key ARN for state bucket encryption"
  type        = string
  default     = null
}
