terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

locals {
  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, { TerraformModule = local.module_label })
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy

  tags = merge(local.default_tags, var.role_tags, { Name = var.role_name })
}

resource "aws_iam_policy" "this" {
  count = var.policy_arn == null ? 1 : 0

  name   = coalesce(var.policy_name, "${var.role_name}-policy")
  policy = var.policy_json

  tags = merge(local.default_tags, var.role_tags, {
    Name = coalesce(var.policy_name, "${var.role_name}-policy")
  })
}

resource "aws_iam_role_policy_attachment" "managed" {
  count = var.policy_arn != null ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = var.policy_arn
}

resource "aws_iam_role_policy_attachment" "inline_policy" {
  count = var.policy_arn == null ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}
