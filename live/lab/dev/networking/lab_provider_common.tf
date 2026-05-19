# Shared lab emulator settings (symlink as lab_provider_common.tf in each root).
# Hybrid: floci :4566 (iam, sts, s3, kms) + ministack :4567 (ec2, elbv2, wafv2).
# IAM stacks: ministack :4567 for all declared services — see docs/support.md.

locals {
  lab_floci_base     = "http://localhost:4566"
  lab_ministack_base = "http://localhost:4567"

  lab_access_key_test = "test"
  lab_secret_key_test = "test"

  lab_hybrid_endpoints = {
    ec2   = local.lab_ministack_base
    elbv2 = local.lab_ministack_base
    wafv2 = local.lab_ministack_base
    iam   = local.lab_floci_base
    sts   = local.lab_floci_base
    s3    = local.lab_floci_base
    kms   = local.lab_floci_base
  }

  lab_ministack_endpoints_iam_s3_sts = {
    iam = local.lab_ministack_base
    s3  = local.lab_ministack_base
    sts = local.lab_ministack_base
  }

  lab_ministack_endpoints_messaging = {
    iam = local.lab_ministack_base
    sns = local.lab_ministack_base
    sqs = local.lab_ministack_base
    sts = local.lab_ministack_base
  }

  lab_ministack_endpoints_s3_events = {
    iam = local.lab_ministack_base
    s3  = local.lab_ministack_base
    sns = local.lab_ministack_base
    sqs = local.lab_ministack_base
    sts = local.lab_ministack_base
  }

  lab_ministack_endpoints_alb = {
    ec2   = local.lab_ministack_base
    elbv2 = local.lab_ministack_base
    iam   = local.lab_ministack_base
    sts   = local.lab_ministack_base
  }

  lab_ministack_endpoints_eks = {
    eks = local.lab_ministack_base
    iam = local.lab_ministack_base
    sts = local.lab_ministack_base
  }

  lab_ministack_endpoints_ec2_iam_sts = {
    ec2 = local.lab_ministack_base
    iam = local.lab_ministack_base
    sts = local.lab_ministack_base
  }

  lab_ministack_endpoints_route53 = {
    iam     = local.lab_ministack_base
    route53 = local.lab_ministack_base
    sts     = local.lab_ministack_base
  }

  lab_ministack_endpoints_iam_sts = {
    iam = local.lab_ministack_base
    sts = local.lab_ministack_base
  }
}
