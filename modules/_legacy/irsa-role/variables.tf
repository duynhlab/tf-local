variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "assume_role_policy" {
  description = "Trust policy JSON for the role"
  type        = string
}

variable "policy_json" {
  description = "Optional inline IAM policy document JSON"
  type        = string
  default     = null
}

variable "policy_arn" {
  description = "Optional managed policy ARN to attach instead of policy_json"
  type        = string
  default     = null
}

variable "policy_name" {
  description = "Name for inline policy when policy_json is set"
  type        = string
  default     = null
}

variable "role_tags" {
  description = "Extra tags for the role and policy"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags merged into default_tags"
  type        = map(string)
  default     = {}
}
