variable "name" {
  description = "Name of the IAM role assumed by EKS pods via Pod Identity."
  type        = string
}

variable "permissions_boundary" {
  description = "ARN of the IAM policy used as the permissions boundary for the role."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Set of managed IAM policy ARNs to attach to the role."
  type        = set(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional JSON IAM policy document to create as a customer-managed policy and attach to the role."
  type        = string
  default     = null
}

variable "associations" {
  description = "Pod Identity associations to create. Map key is a free-form label; each value binds a Kubernetes service account in a namespace on a cluster to this role."
  type = map(object({
    cluster_name    = string
    namespace       = string
    service_account = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
