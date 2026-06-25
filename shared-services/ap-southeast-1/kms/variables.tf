variable "project" {
  description = "Project short slug used as resource name prefix"
  type        = string
  default     = "dnl"
}

variable "tags" {
  description = "Common tags merged onto resources"
  type        = map(string)
  default     = {}
}
