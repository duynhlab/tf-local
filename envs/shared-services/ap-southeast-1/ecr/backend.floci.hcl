# Local floci backend (S3 on :4566). Emulator testing only.
bucket                      = "dnl-tfstate-floci"
key                         = "shared-services/ap-southeast-1/ecr/terraform.tfstate"
region                      = "ap-southeast-1"
access_key                  = "100000000000"
secret_key                  = "test"
use_path_style              = true
skip_credentials_validation = true
skip_requesting_account_id  = true
skip_metadata_api_check     = true
endpoints = {
  s3 = "http://localhost:4566"
}
