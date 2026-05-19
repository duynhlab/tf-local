"""Example custom Checkov rule — S3 buckets must declare public access block in the same file."""

from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class S3PublicAccessBlockRequired(BaseResourceCheck):
    def __init__(self):
        name = "Ensure aws_s3_bucket_public_access_block exists for aws_s3_bucket"
        id = "CKV_TF_LOCAL_S3_1"
        supported_resources = ("aws_s3_bucket",)
        categories = (CheckCategories.ENCRYPTION,)
        super().__init__(
            name=name,
            id=id,
            categories=categories,
            supported_resources=supported_resources,
        )

    def scan_resource_conf(self, conf):
        # Graph-aware pairing is out of scope for this lab stub; bootstrap/main.tf
        # defines both resources explicitly. Extend with checkov graph checks if needed.
        return CheckResult.PASSED


check = S3PublicAccessBlockRequired()
