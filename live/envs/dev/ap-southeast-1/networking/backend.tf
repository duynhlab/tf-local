terraform {
  # S3 native state locking (Terraform >= 1.11) — NO DynamoDB.
  # Stable settings here; bucket/key/region supplied per environment via
  #   terraform init -backend-config=backend.hcl
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
