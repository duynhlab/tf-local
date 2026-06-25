variable "name" {
  type        = string
  description = "Name (or name prefix when use_name_prefix is true) for the security group."
}

variable "use_name_prefix" {
  type        = bool
  description = "When true, use name as a name_prefix instead of a fixed name."
  default     = false
}

variable "description" {
  type        = string
  description = "Description of the security group."
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the security group will be created."
}

variable "ingress_rules" {
  type = map(object({
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
    prefix_list_id               = optional(string)
  }))
  description = "Map of ingress rules. Each rule must set exactly one of cidr_ipv4, cidr_ipv6, referenced_security_group_id, or prefix_list_id."
  default     = {}
}

variable "egress_rules" {
  type = map(object({
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
    prefix_list_id               = optional(string)
  }))
  description = "Map of egress rules. Each rule must set exactly one of cidr_ipv4, cidr_ipv6, referenced_security_group_id, or prefix_list_id."
  default = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources created by this module."
  default     = {}
}
