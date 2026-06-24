locals {
  module_label = basename(abspath(path.module))

  default_tags = merge(var.tags, {
    TerraformModule = local.module_label
  })
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(local.default_tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_key_arn : null
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "log-archive"
    status = "Enabled"

    filter {}

    dynamic "transition" {
      for_each = var.transition_ia_days > 0 ? [1] : []

      content {
        days          = var.transition_ia_days
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "transition" {
      for_each = var.transition_glacier_days > 0 ? [1] : []

      content {
        days          = var.transition_glacier_days
        storage_class = "GLACIER"
      }
    }

    dynamic "expiration" {
      for_each = var.expiration_days > 0 ? [1] : []

      content {
        days = var.expiration_days
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.noncurrent_expiration_days > 0 ? [1] : []

      content {
        noncurrent_days = var.noncurrent_expiration_days
      }
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "DenyNonTLS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = contains(var.log_sources, "s3") ? [1] : []

    content {
      sid    = "S3ServerAccessLogs"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }

      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this.arn}/*"]

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [var.account_id]
      }
    }
  }

  dynamic "statement" {
    for_each = contains(var.log_sources, "alb") ? [1] : []

    content {
      sid    = "ALBAccessLogs"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      }

      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this.arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = contains(var.log_sources, "cloudtrail") ? [1] : []

    content {
      sid    = "CloudTrailGetBucketAcl"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      actions   = ["s3:GetBucketAcl"]
      resources = [aws_s3_bucket.this.arn]
    }
  }

  dynamic "statement" {
    for_each = contains(var.log_sources, "cloudtrail") ? [1] : []

    content {
      sid    = "CloudTrailPutObject"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this.arn}/AWSLogs/${var.account_id}/*"]

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}
