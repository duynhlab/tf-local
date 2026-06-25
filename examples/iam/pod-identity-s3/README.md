# EKS Pod Identity → S3

Modern replacement for IRSA. An app pod (namespace `default`, service account `app`)
assumes an IAM role to read/write an S3 bucket — **no OIDC provider, no IRSA**.

## Pod Identity vs IRSA

| | Pod Identity (this example) | IRSA (legacy, see `cross-account-sns-sqs`) |
|---|---|---|
| Trust principal | Service `pods.eks.amazonaws.com` | Federated OIDC provider ARN |
| Actions | `sts:AssumeRole` + `sts:TagSession` | `sts:AssumeRoleWithWebIdentity` |
| Cluster wiring | `eks-pod-identity-agent` addon + `aws_eks_pod_identity_association` | `aws_iam_openid_connect_provider` + `:sub`/`:aud` conditions |
| Reuse | one role across many clusters | role pinned to one cluster's OIDC issuer |

Module: [`modules/security/pod-identity`](../../../modules/security/pod-identity).
The cluster must run the `eks-pod-identity-agent` addon (the `modules/compute/eks`
wrapper enables it by default).

## Run

```bash
terraform init
terraform validate
# apply needs an existing cluster named var.cluster_name for the association.
```
