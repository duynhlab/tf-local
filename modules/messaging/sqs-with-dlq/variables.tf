variable "queue_name" {
  type = string
}

variable "dlq_name" {
  type = string
}

variable "dlq_max_receive_count" {
  type    = number
  default = 3
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 300
}

variable "message_retention_seconds" {
  type    = number
  default = 345600
}

variable "receive_wait_time_seconds" {
  type    = number
  default = 20
}

variable "dlq_message_retention_seconds" {
  type    = number
  default = 1209600
}

variable "queue_policy_json" {
  type    = string
  default = null
}

variable "queue_tags" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
