terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0"
      configuration_aliases = [aws]
    }
  }
}

locals {
  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, { TerraformModule = local.module_label })
}

resource "aws_sqs_queue" "dlq" {
  provider                  = aws
  name                      = var.dlq_name
  message_retention_seconds = var.dlq_message_retention_seconds
  sqs_managed_sse_enabled   = true

  tags = merge(local.default_tags, var.queue_tags, { Name = var.dlq_name, Role = "dead-letter-queue" })
}

resource "aws_sqs_queue" "main" {
  provider                   = aws
  name                       = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.dlq_max_receive_count
  })

  tags = merge(local.default_tags, var.queue_tags, { Name = var.queue_name, Role = "event-consumer" })
}

resource "aws_sqs_queue_policy" "main" {
  count    = var.queue_policy_json != null ? 1 : 0
  provider = aws

  queue_url = aws_sqs_queue.main.id
  policy    = var.queue_policy_json
}
