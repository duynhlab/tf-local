# tflint-ignore-file: terraform_unused_declarations
# Shared lab emulator settings (symlinked as lab_provider_common.tf in each root).
# floci-only (:4566) — every service endpoint points at floci.
# Local map NAMES are kept stable so existing providers.tf need no changes.
# Multi-account: set the provider access_key to local.lab_accounts.<env> (12-digit
# id => floci treats it as the account id; resources isolate per account).

locals {
  lab_floci_base = "http://localhost:4566"
  # Kept for backward-compat with older references; now also floci.
  lab_ministack_base = local.lab_floci_base

  lab_access_key_test = "test"
  lab_secret_key_test = "test"

  # 12-digit account ids — floci isolates resources per account.
  lab_accounts = {
    shared = "100000000000"
    dev    = "111111111111"
    uat    = "222222222222"
    prod   = "333333333333"
  }

  lab_hybrid_endpoints = {
    ec2   = local.lab_floci_base
    elbv2 = local.lab_floci_base
    wafv2 = local.lab_floci_base
    iam   = local.lab_floci_base
    sts   = local.lab_floci_base
    s3    = local.lab_floci_base
    kms   = local.lab_floci_base
  }

  lab_ministack_endpoints_iam_s3_sts = {
    iam = local.lab_floci_base
    s3  = local.lab_floci_base
    sts = local.lab_floci_base
  }

  lab_ministack_endpoints_messaging = {
    iam = local.lab_floci_base
    sns = local.lab_floci_base
    sqs = local.lab_floci_base
    sts = local.lab_floci_base
  }

  lab_ministack_endpoints_s3_events = {
    iam = local.lab_floci_base
    s3  = local.lab_floci_base
    sns = local.lab_floci_base
    sqs = local.lab_floci_base
    sts = local.lab_floci_base
  }

  lab_ministack_endpoints_alb = {
    ec2   = local.lab_floci_base
    elbv2 = local.lab_floci_base
    iam   = local.lab_floci_base
    sts   = local.lab_floci_base
  }

  lab_ministack_endpoints_eks = {
    eks = local.lab_floci_base
    iam = local.lab_floci_base
    sts = local.lab_floci_base
  }

  lab_ministack_endpoints_ec2_iam_sts = {
    ec2 = local.lab_floci_base
    iam = local.lab_floci_base
    sts = local.lab_floci_base
  }

  lab_ministack_endpoints_route53 = {
    iam     = local.lab_floci_base
    route53 = local.lab_floci_base
    sts     = local.lab_floci_base
  }

  lab_ministack_endpoints_iam_sts = {
    iam = local.lab_floci_base
    sts = local.lab_floci_base
  }
}
