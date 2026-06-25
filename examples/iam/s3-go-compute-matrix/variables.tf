# ---------------------------------------------------------------------------
# Variables — Go BE → S3 Compute Matrix
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for the default provider"
  type        = string
  default     = "ap-southeast-1"
}

variable "secondary_region" {
  description = "Region for the secondary (cross-region) provider"
  type        = string
  default     = "us-east-1"
}

variable "secondary_role_arn" {
  description = "IAM role ARN to assume for the secondary provider"
  type        = string
}

variable "data_account_region" {
  description = "Region for the data_account (cross-account) provider"
  type        = string
  default     = "ap-southeast-1"
}

variable "data_account_role_arn" {
  description = "IAM role ARN to assume for the data_account provider"
  type        = string
}

variable "app_account_id" {
  description = "Account A (Go application workloads)"
  type        = string
  default     = "888888888888"
}

variable "project" {
  type    = string
  default = "go-s3-matrix"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "bucket_same_region" {
  description = "Same-account, same-region bucket (Account A, ap-southeast-1)"
  type        = string
  default     = "go-app-objects-sgn"
}

variable "bucket_cross_region" {
  description = "Same-account, cross-region bucket (Account A, us-east-1)"
  type        = string
  default     = "go-app-objects-iad"
}

variable "bucket_cross_account" {
  description = "Cross-account bucket (Account B, ap-southeast-1)"
  type        = string
  default     = "data-lake-shared"
}

variable "external_id" {
  description = "ExternalId for cross-account AssumeRole (confused-deputy guard)"
  type        = string
  default     = "go-app-2026"
}

variable "tags" {
  type    = map(string)
  default = {}
}
