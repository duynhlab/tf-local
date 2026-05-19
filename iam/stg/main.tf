# ---------------------------------------------------------------------------
# Staging — Cross-Account SNS → SQS with IRSA
#
# Team A (111111111111, us-west-2): SNS Topic + Topic Policy
# Team B (333333333333, ap-southeast-1): SQS + DLQ + Queue Policy + IRSA Role
# ---------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ===========================================================================
# 1. TEAM A RESOURCES (SNS — us-west-2)
# ===========================================================================

#trivy:ignore:AVD-AWS-0095 MiniStack KMS CreateKey fails on aliased providers; using AWS-managed key
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "events" {
  provider          = aws.team_a
  name              = var.sns_topic_name
  kms_master_key_id = "alias/aws/sns"

  tags = merge(local.tags, {
    Name = var.sns_topic_name
    Team = "team-a"
  })
}

# SNS Topic Policy — Allow Team B account to subscribe
resource "aws_sns_topic_policy" "allow_team_b_subscribe" {
  provider = aws.team_a
  arn      = aws_sns_topic.events.arn
  policy   = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowTeamBSubscribe"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.team_b_account_id}:root"]
    }

    actions = [
      "sns:Subscribe",
      "sns:Receive",
    ]

    resources = [aws_sns_topic.events.arn]
  }

  statement {
    sid    = "AllowOwnerFullAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.team_a_account_id}:root"]
    }

    actions   = ["sns:*"]
    resources = [aws_sns_topic.events.arn]
  }
}

# ===========================================================================
# 2. TEAM B RESOURCES (SQS — ap-southeast-1)
# ===========================================================================

data "aws_iam_policy_document" "sqs_queue_policy" {
  statement {
    sid    = "AllowSNSSendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [module.team_b_queues.queue_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.events.arn]
    }
  }
}

module "team_b_queues" {
  source = "../../modules/iam/sqs_with_dlq"

  queue_name            = var.sqs_queue_name
  dlq_name              = var.sqs_dlq_name
  dlq_max_receive_count = var.dlq_max_receive_count
  queue_tags            = { Team = "team-b" }
  tags                  = local.tags
}

resource "aws_sqs_queue_policy" "allow_sns_send" {
  queue_url = module.team_b_queues.queue_url
  policy    = data.aws_iam_policy_document.sqs_queue_policy.json
}

# --- 2d. SNS Subscription (SQS subscribes to SNS topic) ---
resource "aws_sns_topic_subscription" "sqs" {
  provider             = aws.team_a
  topic_arn            = aws_sns_topic.events.arn
  protocol             = "sqs"
  endpoint             = module.team_b_queues.queue_arn
  raw_message_delivery = true
}

# ===========================================================================
# 3. IAM — IRSA Role for EKS consumer pods
# ===========================================================================

# --- 3a. OIDC Provider (represents EKS cluster identity) ---
resource "aws_iam_openid_connect_provider" "eks" {
  url             = "https://${var.eks_oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(local.tags, {
    Name = "eks-oidc-stg"
    Team = "team-b"
  })
}

data "aws_iam_policy_document" "irsa_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "sqs_consumer_permissions" {
  statement {
    sid    = "SQSReadDelete"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [module.team_b_queues.queue_arn]
  }

  statement {
    sid    = "SQSDLQRead"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [module.team_b_queues.dlq_arn]
  }
}

module "sqs_consumer_irsa" {
  source = "../../modules/iam/irsa_role"

  role_name          = "sqs-consumer-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json
  policy_json        = data.aws_iam_policy_document.sqs_consumer_permissions.json
  role_tags          = { Team = "team-b" }
  tags               = local.tags
}
