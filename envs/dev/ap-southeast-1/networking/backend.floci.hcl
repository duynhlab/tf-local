# Local floci backend (S3 on :4566). Use only for emulator testing:
#   terraform init -backend-config=backend.floci.hcl
# Do NOT use for real AWS.
bucket                      = "dnl-tfstate-floci"
key                         = "dev/ap-southeast-1/networking/terraform.tfstate"
region                      = "ap-southeast-1"
access_key                  = "111111111111"
secret_key                  = "test"
use_path_style              = true
skip_credentials_validation = true
skip_requesting_account_id  = true
skip_metadata_api_check     = true
endpoints = {
  s3 = "http://localhost:4566"
}
