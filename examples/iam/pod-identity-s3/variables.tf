variable "project" {
  description = "Project short slug used as resource name prefix"
  type        = string
  default     = "dnl"
}

variable "cluster_name" {
  description = "EKS cluster name to bind the Pod Identity association to"
  type        = string
  default     = "dnl-dev"
}

variable "tags" {
  description = "Common tags merged onto resources"
  type        = map(string)
  default     = {}
}
