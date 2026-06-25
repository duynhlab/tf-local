variable "project" {
  description = "Project short slug used as resource name prefix"
  type        = string
  default     = "dnl"
}

variable "repositories" {
  description = "ECR repository short names (created as <project>/<name>)"
  type        = list(string)
  default     = ["backend", "frontend"]
}

variable "tags" {
  description = "Common tags merged onto resources"
  type        = map(string)
  default     = {}
}
