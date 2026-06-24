variable "name" {
  description = "Name used for the ECS cluster, service, task definition family, and related resources."
  type        = string
}

variable "container_insights" {
  description = "Whether to enable CloudWatch Container Insights on the ECS cluster."
  type        = bool
  default     = true
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy applied to the cluster default and the service."
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number, 0)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    }
  ]
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs for the service."
  type        = number
  default     = 30
}

variable "task_policy_arns" {
  description = "Set of IAM policy ARNs to attach to the ECS task role."
  type        = set(string)
  default     = []
}

variable "execution_managed_policy_arns" {
  description = "Optional AWS-managed policy ARNs to attach to the execution role (real AWS; floci has no managed policies, so leave empty — an inline equivalent is always attached)."
  type        = set(string)
  default     = []
}

variable "cpu" {
  description = "CPU units for the Fargate task definition."
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Memory (MiB) for the Fargate task definition."
  type        = string
  default     = "512"
}

variable "container_definitions" {
  description = "Container definitions for the task definition as a JSON string (caller passes jsonencode([...]))."
  type        = string
}

variable "desired_count" {
  description = "Desired number of running tasks for the service."
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "List of subnet IDs the service tasks are placed in."
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs attached to the service tasks."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the service tasks."
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the load balancer target group to register tasks with. When null, no load balancer is attached."
  type        = string
  default     = null
}

variable "container_name" {
  description = "Name of the container to associate with the load balancer target group."
  type        = string
  default     = null
}

variable "container_port" {
  description = "Port on the container to associate with the load balancer target group."
  type        = number
  default     = null
}

variable "health_check_grace_period" {
  description = "Seconds to ignore failing load balancer health checks after a task starts. Only applies when a target group is set."
  type        = number
  default     = 60
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec for the service tasks."
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "Whether to enable Application Auto Scaling for the service."
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number of tasks when autoscaling is enabled."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks when autoscaling is enabled."
  type        = number
  default     = 4
}

variable "cpu_target" {
  description = "Target average CPU utilization percentage for the autoscaling policy."
  type        = number
  default     = 70
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources."
  type        = map(string)
  default     = {}
}
