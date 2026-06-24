variable "alias_name" {
  description = "Alias name for the KMS key (without the \"alias/\" prefix). Also used as the Name tag."
  type        = string
}

variable "description" {
  description = "Description of the KMS key."
  type        = string
  default     = ""
}

variable "enable_key_rotation" {
  description = "Whether to enable automatic annual rotation of the key material."
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "Number of days to wait before the key is deleted after destruction (7-30)."
  type        = number
  default     = 30
}

variable "multi_region" {
  description = "Whether the KMS key is a multi-region key."
  type        = bool
  default     = false
}

variable "key_admin_arns" {
  description = "IAM principal ARNs granted key administration permissions."
  type        = list(string)
  default     = []
}

variable "key_user_arns" {
  description = "IAM principal ARNs granted key usage (encrypt/decrypt) permissions."
  type        = list(string)
  default     = []
}

variable "cross_account_ids" {
  description = "AWS account IDs granted cross-account key usage (encrypt/decrypt) permissions."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
