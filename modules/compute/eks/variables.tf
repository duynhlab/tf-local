variable "name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.33"
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster and its nodes will be provisioned."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the EKS managed node groups will be placed."
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "List of subnet IDs for the EKS control plane ENIs. Falls back to subnet_ids in the upstream module when empty."
  type        = list(string)
  default     = []
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Whether to add the identity that creates the cluster as a cluster admin via an access entry."
  type        = bool
  default     = true
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions passed through to the upstream module."
  type        = any
  default     = {}
}

variable "addons" {
  description = "Map of cluster addon configurations. Includes eks-pod-identity-agent so Pod Identity associations work."
  type        = any
  default = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
  }
}

variable "access_entries" {
  description = "Map of EKS access entries (cluster authentication/authorization) passed through to the upstream module."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources created by the module."
  type        = map(string)
  default     = {}
}
