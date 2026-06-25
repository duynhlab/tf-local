variable "bucket_name" {
  description = "Name of the log-archive S3 bucket."
  type        = string
}

variable "account_id" {
  description = "AWS account ID that owns this bucket and is the source of delivered logs."
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow the bucket to be destroyed while it still contains objects."
  type        = bool
  default     = false
}

variable "object_ownership" {
  description = "Object ownership setting for the bucket. BucketOwnerEnforced disables ACLs."
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm. Either AES256 or aws:kms."
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "KMS key ARN to use when sse_algorithm is aws:kms. Ignored for AES256."
  type        = string
  default     = null
}

variable "transition_ia_days" {
  description = "Days after which current objects transition to STANDARD_IA. Set to 0 to disable."
  type        = number
  default     = 30
}

variable "transition_glacier_days" {
  description = "Days after which current objects transition to GLACIER. Set to 0 to disable."
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Days after which current objects expire. Set to 0 to disable."
  type        = number
  default     = 365
}

variable "noncurrent_expiration_days" {
  description = "Days after which noncurrent object versions expire. Set to 0 to disable."
  type        = number
  default     = 30
}

variable "log_sources" {
  description = "Set of log sources allowed to write to this bucket. Subset of [\"s3\", \"alb\", \"cloudtrail\"]."
  type        = set(string)
  default     = ["s3"]

  validation {
    condition     = length(setsubtract(var.log_sources, ["s3", "alb", "cloudtrail"])) == 0
    error_message = "log_sources must be a subset of [\"s3\", \"alb\", \"cloudtrail\"]."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
