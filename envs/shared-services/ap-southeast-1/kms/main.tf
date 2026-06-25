# Shared CMK in the shared-services account, usable cross-account by workloads.
module "shared_kms" {
  source = "../../../../modules/data/kms-key"

  alias_name  = "${var.project}-shared"
  description = "Shared CMK for ${var.project} workloads (cross-account)"

  enable_key_rotation = true
  cross_account_ids   = var.workload_account_ids

  tags = var.tags
}
