variable "name" {
  description = "Name of the IAM role."
  type        = string
}

variable "description" {
  description = "Description of the IAM role."
  type        = string
  default     = ""
}

variable "path" {
  description = "Path under which to create the IAM role."
  type        = string
  default     = "/"
}

variable "assume_role_policy_json" {
  description = "Raw trust (assume role) policy as a JSON string. When set, it is used verbatim and the trusted_* variables are ignored. When null, the trust policy is built from trusted_services, trusted_role_arns, and trusted_account_ids."
  type        = string
  default     = null
}

variable "trusted_services" {
  description = "List of AWS service principals allowed to assume the role (e.g. [\"ecs-tasks.amazonaws.com\"]). Used only when assume_role_policy_json is null."
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "List of IAM role/user ARNs (AWS principals) allowed to assume the role. Used only when assume_role_policy_json is null."
  type        = list(string)
  default     = []
}

variable "trusted_account_ids" {
  description = "List of AWS account IDs whose root principal is allowed to assume the role. Used only when assume_role_policy_json is null."
  type        = list(string)
  default     = []
}

variable "permissions_boundary" {
  description = "ARN of the policy used as the permissions boundary for the role."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration (in seconds) for the role. Between 3600 and 43200."
  type        = number
  default     = 3600
}

variable "force_detach_policies" {
  description = "Whether to force detaching any policies the role has before destroying it."
  type        = bool
  default     = true
}

variable "managed_policy_arns" {
  description = "Set of managed IAM policy ARNs to attach to the role."
  type        = set(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Customer-managed policy document as a JSON string. When set, an aws_iam_policy is created and attached to the role."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all taggable resources."
  type        = map(string)
  default     = {}
}
