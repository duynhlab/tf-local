# EKS Pod Identity → S3 (modern replacement for IRSA).
# Contrast with examples/iam/cross-account-sns-sqs (legacy IRSA via OIDC).

module "app_bucket" {
  source = "../../../modules/data/s3-bucket"

  bucket_name = "${var.project}-dev-podid-demo"
  tags        = var.tags
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid       = "ReadWriteAppBucket"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [module.app_bucket.bucket_arn, "${module.app_bucket.bucket_arn}/*"]
  }
}

module "pod_identity" {
  source = "../../../modules/security/pod-identity"

  name               = "${var.project}-dev-app-s3"
  inline_policy_json = data.aws_iam_policy_document.s3_access.json

  associations = {
    app = {
      cluster_name    = var.cluster_name
      namespace       = "default"
      service_account = "app"
    }
  }

  tags = var.tags
}
