variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow the bucket to be destroyed even when it still contains objects."
  type        = bool
  default     = false
}

variable "object_ownership" {
  description = "Object ownership setting controlling ACL behavior for the bucket."
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "versioning_enabled" {
  description = "Whether to enable object versioning on the bucket."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for server-side encryption. When null, AES256 (SSE-S3) is used."
  type        = string
  default     = null
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for the bucket."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for the bucket."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for the bucket."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for the bucket."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules to apply to the bucket."
  type = list(object({
    id      = string
    enabled = bool
    prefix  = optional(string)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days                    = optional(number)
    noncurrent_version_expiration_days = optional(number)
  }))
  default = []
}

variable "logging_target_bucket" {
  description = "Target bucket for S3 server access logs. When null, access logging is disabled."
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "Key prefix for S3 server access log objects in the target bucket."
  type        = string
  default     = null
}

variable "enforce_tls" {
  description = "Whether to attach a bucket policy denying requests not using TLS."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
