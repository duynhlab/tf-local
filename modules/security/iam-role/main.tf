###############################################################################
# IAM Role Module – Role with trust policy, managed and inline policies
#
# Creates an IAM role whose trust policy is supplied verbatim or built from
# trusted services/role ARNs/account IDs. Attaches managed policies and,
# optionally, a single customer-managed policy from an inline JSON document.
###############################################################################

locals {
  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, { TerraformModule = local.module_label })

  # Use the raw JSON trust policy when provided, otherwise build one.
  assume_role_policy = var.assume_role_policy_json != null ? var.assume_role_policy_json : data.aws_iam_policy_document.assume.json

  create_policy = var.inline_policy_json != null
}

# ─── Trust Policy ────────────────────────────────────────────────────────────
data "aws_iam_policy_document" "assume" {
  dynamic "statement" {
    for_each = length(var.trusted_services) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "Service"
        identifiers = var.trusted_services
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.trusted_role_arns) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "AWS"
        identifiers = var.trusted_role_arns
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.trusted_account_ids) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "AWS"
        identifiers = [for id in var.trusted_account_ids : "arn:aws:iam::${id}:root"]
      }
    }
  }
}

# ─── Role ────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "this" {
  name                  = var.name
  description           = var.description
  path                  = var.path
  assume_role_policy    = local.assume_role_policy
  permissions_boundary  = var.permissions_boundary
  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies

  tags = merge(local.default_tags, { Name = var.name })
}

# ─── Customer-Managed Policy (optional) ──────────────────────────────────────
resource "aws_iam_policy" "this" {
  count = local.create_policy ? 1 : 0

  name        = var.name
  path        = var.path
  description = var.description
  policy      = var.inline_policy_json

  tags = merge(local.default_tags, { Name = var.name })
}

resource "aws_iam_role_policy_attachment" "customer" {
  count = local.create_policy ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

# ─── Managed Policy Attachments ──────────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.managed_policy_arns

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
