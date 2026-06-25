# NOTE: Terraform does not support marking a whole map(object(...)) variable as
# `sensitive` while it also uses `optional()` attributes. The nested `value`
# field is the sensitive part; it is referenced as a sensitive value in main.tf.
variable "parameters" {
  description = <<-EOT
    Map of SSM parameters to create. The map KEY is the full parameter name
    (a hierarchical path such as "/dev/app/db_host"). Each value supports:
      - value       : (required) the parameter value
      - type        : "String" | "StringList" | "SecureString" (default "String")
      - description  : free-text description (default "")
      - tier        : "Standard" | "Advanced" | "Intelligent-Tiering" (default "Standard")
      - key_id      : KMS key id/alias/ARN, only meaningful for SecureString.
                      null => AWS-managed default alias/aws/ssm.
    WARNING: For SecureString parameters the plaintext value is stored in
    Terraform state. Protect state accordingly (encrypted backend, restricted access).
  EOT

  type = map(object({
    value       = string
    type        = optional(string, "String")
    description = optional(string, "")
    tier        = optional(string, "Standard")
    key_id      = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to every created SSM parameter."
  type        = map(string)
  default     = {}
}
