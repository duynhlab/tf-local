terraform {
  # S3 native state locking (Terraform >= 1.11) — NO DynamoDB.
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
