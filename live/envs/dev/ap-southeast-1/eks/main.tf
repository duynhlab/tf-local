# EKS dev cluster (wraps terraform-aws-modules/eks) + a Pod Identity binding.
# NOTE: floci's EKS surface is limited — this root is primarily validate/plan.
# Reads the dev networking stack (apply networking first).
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../networking/terraform.tfstate"
  }
}

module "eks" {
  source = "../../../../../modules/compute/eks"

  name               = "${var.project}-dev"
  kubernetes_version = "1.33"
  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids         = data.terraform_remote_state.networking.outputs.app_subnet_ids

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }
  }

  tags = var.tags
}

# Pod Identity (NOT IRSA): app SA -> IAM role, bound to this cluster.
module "app_pod_identity" {
  source = "../../../../../modules/security/pod-identity"

  name = "${var.project}-dev-eks-app"

  associations = {
    app = {
      cluster_name    = module.eks.cluster_name
      namespace       = "default"
      service_account = "app"
    }
  }

  tags = var.tags
}
