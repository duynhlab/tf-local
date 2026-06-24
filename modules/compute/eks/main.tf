# Wrapper over terraform-aws-modules/eks. Pod Identity (not IRSA) via the
# eks-pod-identity-agent addon + separate aws_eks_pod_identity_association
# (see modules/security/pod-identity).

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.6"

  name                                     = var.name
  kubernetes_version                       = var.kubernetes_version
  vpc_id                                   = var.vpc_id
  subnet_ids                               = var.subnet_ids
  control_plane_subnet_ids                 = var.control_plane_subnet_ids
  endpoint_public_access                   = var.endpoint_public_access
  endpoint_private_access                  = var.endpoint_private_access
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  eks_managed_node_groups                  = var.eks_managed_node_groups
  addons                                   = var.addons
  access_entries                           = var.access_entries
  tags                                     = var.tags
}
