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

variable "tags" {
  description = "Common tags merged onto resources"
  type        = map(string)
  default     = {}
}
