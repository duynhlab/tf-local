terraform {
  # S3 native state locking (Terraform >= 1.11) — NO DynamoDB.
  # bucket/key/region via: terraform init -backend-config=backend.hcl
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
