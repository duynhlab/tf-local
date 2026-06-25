locals {
  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, { TerraformModule = local.module_label })
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "key_policy" {
  statement {
    sid       = "EnableRootPermissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = length(var.key_admin_arns) > 0 ? [1] : []

    content {
      sid = "KeyAdmins"
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:ReplicateKey",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_admin_arns
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.key_user_arns) > 0 ? [1] : []

    content {
      sid = "KeyUsers"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_user_arns
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.cross_account_ids) > 0 ? [1] : []

    content {
      sid = "CrossAccount"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = [for id in var.cross_account_ids : "arn:aws:iam::${id}:root"]
      }
    }
  }
}

resource "aws_kms_key" "this" {
  description              = var.description
  enable_key_rotation      = var.enable_key_rotation
  deletion_window_in_days  = var.deletion_window_in_days
  multi_region             = var.multi_region
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy                   = data.aws_iam_policy_document.key_policy.json

  tags = merge(local.default_tags, { Name = var.alias_name })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias_name}"
  target_key_id = aws_kms_key.this.key_id
}
