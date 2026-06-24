# EKS Pod Identity (modern replacement for IRSA)
#
# Pod Identity vs IRSA:
#   - Trust is granted to the AWS service principal "pods.eks.amazonaws.com"
#     (not a per-cluster OIDC provider). The trust policy uses the actions
#     sts:AssumeRole AND sts:TagSession -- both are required; TagSession lets
#     EKS attach session tags (cluster/namespace/service-account) at assume time.
#   - No OIDC provider, no aws_iam_openid_connect_provider, no
#     sts:AssumeRoleWithWebIdentity, and no :sub/:aud trust conditions.
#   - A single role is reusable across multiple clusters -- bindings are made
#     out-of-band via aws_eks_pod_identity_association rather than baked into
#     the trust policy.
#   - Requires the "eks-pod-identity-agent" addon to be installed on each
#     target cluster.

locals {
  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, { TerraformModule = local.module_label })
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  assume_role_policy   = data.aws_iam_policy_document.assume.json
  permissions_boundary = var.permissions_boundary

  tags = merge(local.default_tags, { Name = var.name })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.managed_policy_arns

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_policy" "this" {
  count = var.inline_policy_json != null ? 1 : 0

  name   = var.name
  policy = var.inline_policy_json

  tags = merge(local.default_tags, { Name = var.name })
}

resource "aws_iam_role_policy_attachment" "inline" {
  count = var.inline_policy_json != null ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

resource "aws_eks_pod_identity_association" "this" {
  for_each = var.associations

  cluster_name    = each.value.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = aws_iam_role.this.arn

  tags = local.default_tags
}
