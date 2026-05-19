# Landing zone (Track B)

Multi-account layout for **real AWS** stacks under `live/aws/`. Emulator lab work stays in `live/lab/`.

## Account model

Copy `config/accounts.yaml.example` → `config/accounts.yaml` (gitignored) and replace placeholder IDs.

| OU / role | Example account | Terraform use |
|-----------|-----------------|---------------|
| Management | `management_account_id` | Org / SCPs (out of repo) |
| Security — log archive | `log_archive_account_id` | Central logs |
| Security — audit | `audit_account_id` | Security tooling |
| Infrastructure — network prod | `network_prod_account_id` | `live/aws/prod/...` via `assume_role` |
| Infrastructure — network dev | `network_dev_account_id` | `live/aws/dev/...` direct or role |
| Workloads — app prod / dev | `app_prod_account_id`, `app_dev_account_id` | Future app stacks |

## State

1. Run `bootstrap/` once (local backend) to create the versioned, encrypted state bucket.
2. Per stack: `terraform init -backend-config=backend.hcl` using `backend.hcl.example` as a template.
3. State keys: `<env>/<region>/<component>/terraform.tfstate`.

## Networking roots

| Stack | Path | Auth |
|-------|------|------|
| Dev VPC | `live/aws/dev/ap-southeast-1/networking/` | Default OIDC role in dev account |
| Prod VPC | `live/aws/prod/ap-southeast-1/networking/` | `assume_role_arn` → network prod account |

CIDRs: **`docs/subnet.csv`** only.

## CI (GitHub Actions)

Workflow: `.github/workflows/aws-ci.yml`

| Variable / secret | Purpose |
|-------------------|---------|
| `AWS_DEV_ROLE_ARN` | OIDC role for dev plan |
| `AWS_PROD_NETWORK_ROLE_ARN` | OIDC role for prod network plan |
| `TF_STATE_BUCKET` | Remote state bucket name |

Plans upload `tfplan` artifacts; apply remains manual or a separate gated workflow.

## Spoke vs landing zone

Landing zone accounts hold org-wide logging, security, and shared networking. Spoke workload accounts peer or attach via TGW (future stacks); this repo currently ships **single-VPC networking** roots only.
