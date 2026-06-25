variable "project" {
  description = "Project short slug used as resource name prefix"
  type        = string
  default     = "dnl"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "workload_account_ids" {
  description = "Workload account IDs granted cross-account access (dev/uat/prod). Real account numbers on AWS."
  type        = list(string)
  default     = ["111111111111", "222222222222", "333333333333"]
}

variable "tags" {
  description = "Common tags merged onto resources"
  type        = map(string)
  default     = {}
}
