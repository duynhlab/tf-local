# Terraform AWS Networking Lab

Terraform lab demonstrating enterprise-style AWS patterns against two complementary local emulators:

| Emulator | Host port | Role |
|---|---|---|
| **[floci](https://floci.io)** | `:4566` | Compute / identity / data plane — IAM, STS, S3, SNS, SQS, KMS, **EKS (real k3s)**, Lambda, ECS, ECR, RDS, ElastiCache, MSK, OpenSearch, Athena |
| **[MiniStack](https://github.com/ministackorg/ministack)** | `:4567` | Enterprise networking + edge — advanced EC2/VPC (NAT GW, VPC Endpoints, NACL, Flow Logs, Peering, Egress-only IGW), ELBv2, **WAF v2** |

The Terraform providers split their `endpoints {}` block across the two emulators per service — see [`environments/dev/providers.tf`](environments/dev/providers.tf) and [`environments/prod/providers.tf`](environments/prod/providers.tf). The full per-service matrix is in [`docs/support.md`](docs/support.md).

## Prerequisites

- [Podman](https://podman.io/getting-started/installation) (preferred) or Docker, with Compose
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) v2

## Quick Start

```bash
# 1. Start floci + ministack
./scripts/setup.sh

# 2. Run full validation workflow (dev + prod)
./scripts/test-all.sh

# 3. Teardown when done
./scripts/teardown.sh
```

## Environment Overview

### dev environment
- **Purpose:** quick single-VPC validation
- **Topology:** one VPC, 3-tier subnets (Public/App/Data), 3 AZs
- **Endpoints:** `ec2 / elbv2 / wafv2 → :4567`, `iam / sts / s3 / kms → :4566`

### prod environment
- **Purpose:** enterprise networking patterns + edge security
- **Topology:** multi-region 3-tier with peering, PrivateLink, TGW, WAF v2 (toggles in `environments/prod/terraform.tfvars`)
- **Endpoints:** same hybrid split, three regional provider aliases (`default`, `ap_southeast_1`, `us_east_1`)

### iam/* case studies
Each subdirectory under `iam/` is a standalone Terraform root demonstrating a real-world IAM scenario (cross-account SNS→SQS, IRSA + Pod Identity for the AWS Load Balancer Controller, S3 events fan-out, etc.). They target **ministack `:4567`** because the patterns require `aws_iam_openid_connect_provider`, `aws_ebs_snapshot`, and full ELBv2 attributes that floci does not implement.

## Project Structure

```
.
├── docker-compose.yml              # Hybrid stack: floci + ministack
├── modules/
│   ├── vpc-base/                   # VPC, subnets, route tables, IGW, NAT, optional VPC endpoints
│   ├── vpc-peering/                # Cross-region VPC peering
│   ├── privatelink/                # NLB + VPC Endpoint Service + Endpoint
│   ├── transit-gateway/            # Multi-region TGW hub-and-spoke
│   └── waf-v2/                     # WebACL, IPSet, association
├── environments/
│   ├── dev/                        # Singapore, 3 AZs
│   └── prod/                       # Multi-region (SG, US-East)
├── iam/                            # IAM-focused case studies (13 roots)
├── scripts/
│   ├── setup.sh                    # Bring up floci + ministack (podman compose)
│   ├── teardown.sh                 # Down + optional terraform destroy
│   ├── test-all.sh                 # Full dev + prod validation
│   └── validate-ministack-apis.sh  # Probes ministack APIs (now on :4567)
├── docs/
│   ├── README.md                   # Architecture analysis
│   ├── support.md                  # Per-service support matrix (floci + ministack)
│   ├── subnet.csv                  # CIDR source of truth
│   └── report.md                   # Findings
└── AGENTS.md                       # AI agent rules
```

## Networking Modules

| Module | Purpose | Backed by |
|---|---|---|
| **vpc-base** | Foundation networking + optional S3/KMS/STS VPC endpoints | ministack `:4567` |
| **vpc-peering** | Cross-region peering | ministack `:4567` |
| **privatelink** | NLB + VPC Endpoint Service (gated, see support matrix) | ministack `:4567` |
| **transit-gateway** | TGW hub-and-spoke (gated, see support matrix) | ministack `:4567` |
| **waf-v2** | WebACL, IP sets | ministack `:4567` |

## Health checks

```bash
curl -s http://localhost:4566/_localstack/health  | python3 -m json.tool   # floci
curl -s http://localhost:4567/_ministack/health   | python3 -m json.tool   # ministack
```

## Troubleshooting

- **Compose engine:** scripts auto-detect `podman-compose` → `podman compose` → `docker compose`.
- **Containers not starting:** `podman compose logs floci ministack`.
- **Docker socket:** floci EKS/Lambda/EC2/ECS require `/var/run/docker.sock`. The compose file already mounts it.
- **CIDR drift:** always consult `docs/subnet.csv` before adding new CIDR blocks.

## Documentation

- [`AGENTS.md`](AGENTS.md) — AI agent rules and runbook
- [`docs/support.md`](docs/support.md) — per-service emulator support matrix
- [`docs/README.md`](docs/README.md) — architecture analysis
- [`docs/subnet.csv`](docs/subnet.csv) — CIDR allocation
