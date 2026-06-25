# Shared ECR repos; workload accounts (dev/uat/prod) get cross-account pull.
module "ecr" {
  source   = "../../../../modules/compute/ecr"
  for_each = toset(var.repositories)

  name             = "${var.project}/${each.key}"
  pull_account_ids = var.workload_account_ids

  tags = var.tags
}
