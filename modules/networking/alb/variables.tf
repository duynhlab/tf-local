variable "name" {
  type        = string
  description = "Name of the Application Load Balancer."
}

variable "target_group_name" {
  type        = string
  description = "Name of the target group fronted by the load balancer."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which the target group is created."
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to attach to the load balancer (typically public subnets)."
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to associate with the load balancer."
}

variable "internal" {
  type        = bool
  description = "Whether the load balancer is internal (true) or internet-facing (false)."
  default     = false
}

variable "target_port" {
  type        = number
  description = "Port on which the targets receive traffic."
  default     = 8080
}

variable "listener_port" {
  type        = number
  description = "Port on which the load balancer listens for incoming HTTP traffic."
  default     = 80
}

variable "health_check_path" {
  type        = string
  description = "Destination path for the target group health check."
  default     = "/"
}

variable "health_check_matcher" {
  type        = string
  description = "HTTP response code(s) considered healthy by the target group health check."
  default     = "200"
}

variable "deregistration_delay" {
  type        = number
  description = "Time in seconds to wait before deregistering a target (connection draining)."
  default     = 30
}

variable "idle_timeout" {
  type        = number
  description = "Time in seconds that a connection is allowed to be idle on the load balancer."
  default     = 60
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Whether deletion protection is enabled on the load balancer."
  default     = false
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN. When set, an HTTPS:443 listener is created and HTTP redirects to it. Leave null for the HTTP-only lab path."
  default     = null
}

variable "ssl_policy" {
  type        = string
  description = "SSL policy for the HTTPS listener (used only when certificate_arn is set)."
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources created by this module."
  default     = {}
}
