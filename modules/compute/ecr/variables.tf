variable "name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository. Valid values are MUTABLE or IMMUTABLE."
  type        = string
  default     = "IMMUTABLE"
}

variable "force_delete" {
  description = "If true, delete the repository even if it contains images."
  type        = bool
  default     = false
}

variable "scan_on_push" {
  description = "Whether images are scanned for vulnerabilities after being pushed."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of a KMS key to encrypt the repository. When null, AES256 encryption is used."
  type        = string
  default     = null
}

variable "enable_lifecycle_policy" {
  description = "Whether to attach a lifecycle policy to the repository."
  type        = bool
  default     = true
}

variable "untagged_expire_days" {
  description = "Number of days after which untagged images expire."
  type        = number
  default     = 14
}

variable "keep_last_tagged" {
  description = "Number of most recent tagged images to retain."
  type        = number
  default     = 10
}

variable "tag_prefix_list" {
  description = "Tag prefixes that the keep-last-tagged lifecycle rule applies to."
  type        = list(string)
  default     = ["v"]
}

variable "pull_account_ids" {
  description = "AWS account IDs granted cross-account pull access to the repository."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
