# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor) working in this repository.

---

## Purpose

Terraform lab for **enterprise-style AWS networking + identity** using a **hybrid** local emulator stack:

| Emulator | Host port | Role |
|---|---|---|
| **floci** | `:4566` | Compute / identity / data plane — IAM, STS, S3, SNS, SQS, KMS, EKS (real k3s), Lambda, ECS, ECR, RDS, ElastiCache, MSK, OpenSearch, Athena |
| **ministack** | `:4567` | Enterprise networking + edge — advanced EC2/VPC (NAT GW, VPC Endpoints, NACL, Flow Logs, Peering, Egress-only IGW), ELBv2, WAF v2 |

Both run side-by-side via `docker-compose.yml` and Podman.

| Environment | Endpoint mapping |
|-------------|-----------------|
| `environments/dev`  | `ec2/elbv2/wafv2 → :4567`, `iam/sts/s3/kms → :4566` |
| `environments/prod` | same hybrid split, three regional provider aliases |
| `iam/*`             | all services on ministack `:4567` (needs `aws_iam_openid_connect_provider`, `aws_ebs_snapshot`, full ELBv2 attrs — floci does not implement these) |

`prod` is the multi-pattern scenario: VPC peering, PrivateLink, Transit Gateway hub–spoke, plus a 3-tier **main / ingress** VPC (`module.main_vpc`, IGW → public / app / data).

---

## Lab scope

Use **`docs/subnet.csv`** for CIDRs. Intended learning areas:

- **Identity** (floci): IAM, STS, IRSA / Pod Identity patterns, optional **IAM policy enforcement** (`FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true`).
- **Data & edge** (mixed): S3 + bucket policies / versioning / encryption / public access block (floci); WAF v2 (ministack).
- **EC2 networking** (ministack): VPC, subnets, IGW, NAT, egress-only IGW, route tables, VPC endpoints, peering (TGW / PrivateLink gated — see support matrix).
- **EC2 attachments** (ministack): SGs, EIPs, ENIs, key pairs.
- **Core hardening** (ministack): NACLs, Flow Logs, EBS.
- **Compute** (floci): EKS clusters via real k3s (mock mode available via `FLOCI_SERVICES_EKS_MOCK=true`), Lambda real runtimes, ECS, real EC2 containers.

API-level details: **[docs/support.md](docs/support.md)** (authoritative matrix, per emulator).

---

## Repository layout

```text
docker-compose.yml             # floci :4566 + ministack :4567 + ./volume/{floci,ministack}
bootstrap/                     # One-time S3 state bucket (real AWS, local backend)
config/
  accounts.yaml.example        # Multi-account map (copy → accounts.yaml, gitignored)
docs/
  subnet.csv                   # CIDR source of truth
  support.md                   # Combined floci + ministack support matrix
  landing-zone.md              # Track B account / state layout
  compliance.md                # Checkov / Trivy policy gates
  terragrunt-decision.md       # Why plain Terraform roots (no Terragrunt)
  module-versioning.md         # In-repo module pins and lock files
live/
  lab/dev/networking/          # Emulator dev VPC (hybrid endpoints)
  lab/prod/networking/         # Emulator prod (peering, TGW, PL toggles)
  aws/dev/ap-southeast-1/networking/   # Real AWS dev VPC
  aws/prod/ap-southeast-1/networking/ # Real AWS prod (assume_role)
environments/                  # Deprecated → use live/lab/* (see environments/README.md)
iam/
  alb-controller/              # IRSA + Pod Identity for AWS Load Balancer Controller
  cluster-access/              # EKS access entries (optional toggle)
  cross-account/               # Cross-account S3 access
  cross-account-secrets/       # Cross-account Secrets Manager
  cross-region-pipeline/       # CodePipeline cross-region SNS/SQS
  cross-region-s3/             # Cross-region S3 replication
  external-dns-cross-account/  # ExternalDNS cross-account Route53
  prod/                        # Prod cross-account SNS→SQS fan-out
  s3-eks/                      # S3 access from EKS workloads
  s3-events/                   # S3 → SNS → SQS fan-out
  s3-go-compute-matrix/        # Go BE compute matrix IAM cases
  stg/                         # Staging cross-account SNS→SQS
  storage-drivers/             # EBS / EFS CSI driver IAM
modules/
  lab-provider/                # Shared emulator endpoint maps
  networking/vpc/              # 3-tier VPC (successor to vpc-base)
  iam/irsa_role/, iam/sqs_with_dlq/
  vpc-peering/, privatelink/, transit-gateway/, waf-v2/
policies/checkov/              # Custom Checkov rules (AWS CI hard fail)
tests/                         # terraform test (plan-only module smoke)
examples/networking/minimal/
scripts/
  setup.sh                     # podman/docker compose up floci + ministack
  teardown.sh                  # down -v (+ optional terraform destroy)
  test-all.sh                  # dev + prod full apply/destroy cycle
  validate-ministack-apis.sh   # API probe against ministack (:4567)
.github/workflows/
  ci.yml                       # Lab emulator CI
  aws-ci.yml                   # Real AWS validate / plan / Checkov / drift schedule
```

Each `live/*`, `iam/*`, and `bootstrap/` directory is a **standalone** Terraform root module.

---

## Runbook

1. **Start both emulators**

   ```bash
   ./scripts/setup.sh
   ```

   Auto-detects `podman-compose` → `podman compose` → `docker compose`. Podman is preferred.

2. **Health checks**

   ```bash
   curl -sf http://localhost:4566/_localstack/health  # floci
   curl -sf http://localhost:4567/_ministack/health   # ministack
   ```

3. **Validate dev and prod**

   ```bash
   terraform -chdir=environments/dev fmt -check
   terraform -chdir=environments/dev init -input=false
   terraform -chdir=environments/dev validate
   terraform -chdir=environments/dev apply -auto-approve
   terraform -chdir=environments/dev output
   terraform -chdir=environments/dev destroy -auto-approve

   terraform -chdir=environments/prod fmt -check
   terraform -chdir=environments/prod init -input=false
   terraform -chdir=environments/prod validate
   terraform -chdir=environments/prod apply -auto-approve
   terraform -chdir=environments/prod output
   terraform -chdir=environments/prod destroy -auto-approve
   ```

4. **Validate iam/\***

   ```bash
   for d in iam/*/; do
     terraform -chdir="$d" init -input=false && \
     terraform -chdir="$d" validate && \
     terraform -chdir="$d" apply -auto-approve && \
     terraform -chdir="$d" destroy -auto-approve
   done
   ```

5. **Stop**

   ```bash
   ./scripts/teardown.sh                # just stop containers
   CONFIRM_DESTROY=1 ./scripts/teardown.sh   # also destroy each root first
   ```

---

## Provider rules

- Shared emulator endpoint maps live in [`modules/lab-provider/common.tf`](modules/lab-provider/common.tf); each root symlinks `lab_provider_common.tf` and references `local.lab_hybrid_endpoints` or `local.lab_ministack_endpoints_*` in `providers.tf`.

- Keep the **hybrid `endpoints { … }`** block:

  | Endpoint | URL |
  |---|---|
  | `ec2`, `elbv2`, `wafv2` | `http://localhost:4567` (ministack) |
  | `iam`, `sts`, `s3`, `kms` | `http://localhost:4566` (floci) |

- Keep:
  - `skip_credentials_validation = true`
  - `skip_metadata_api_check     = true`
  - `skip_requesting_account_id  = true`
  - `access_key = "test"` / `secret_key = "test"` (or the lab account number)
  - `s3_use_path_style = true`

- Never use real AWS credentials, real account IDs, or real ARNs in lab code.
- For `environments/prod`, the regional provider aliases (`default`, `ap_southeast_1`, `us_east_1`) all share the same `local.endpoints` map.

### `hashicorp/aws` version

- Use **`>= 6.0`**.
- MiniStack is explicitly compatible with provider v5 and v6.
- Floci is LocalStack-Community wire-compatible (port `4566`, parity layer); provider v6 works.
- **Commit** every `environments/*/.terraform.lock.hcl` and `iam/*/.terraform.lock.hcl` so CI resolves the same build.

---

## Known emulation limitations

| Resource | Where | Workaround |
|----------|-------|------------|
| `aws_ec2_transit_gateway` | ministack — `CreateTransitGateway` not implemented | `enable_transit_gateway = false` (default) |
| `aws_vpc_endpoint_service` | ministack — `CreateVpcEndpointServiceConfiguration` not implemented | `enable_privatelink = false` (default) |
| `aws_ec2_transit_gateway_peering_attachment_accepter` | ministack — waiter may not complete | `enable_tgw_cross_region_peering = false` (default) |
| IAM policy enforcement | floci — disabled unless `FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true` | Opt-in; bypass rules described in floci IAM docs |
| `aws_eks_access_entry` | floci — `CreateAccessEntry` not in floci's EKS surface | `enable_eks_access_entries = false` (default in `iam/cluster-access`) |
| `aws_kms_key` on aliased providers | ministack — `UnrecognizedClientException` | Use default provider or AWS-managed alias |
| `aws_s3_bucket_public_access_block` destroy | ministack — `found resource` after DELETE | Restart the ministack container (`podman compose restart ministack`) to reset state, or skip destroy in CI |

Full tables: **[docs/support.md](docs/support.md)**.

---

## Allowed and disallowed Terraform commands

**Allowed:** `init`, `fmt`, `fmt -check`, `validate`, `plan`, `test`, `output`, `state list`, `state show <addr>`.

**Disallowed:** `import`, `state mv`, `state rm`, `state push`, `state pull`.

Use `apply` / `destroy` only for **local emulator** validation and document intent.

---

## Module selection

1. `modules/networking/vpc/` (formerly `vpc-base`) for VPC / subnet / route / IGW / NAT / VPC endpoint patterns.
2. Other `modules/*` when they fit.
3. Plain `resource` blocks only if no module fits.
4. External registry modules only when explicitly requested.

Do not add new providers or external modules without a clear request.

---

## Service-specific guidance

- **S3** (floci): `aws_s3_bucket` + separate `aws_s3_bucket_policy`; add versioning, encryption, public access block unless the exercise needs public access.
- **EC2** (ministack): explicit SGs; prefer separate ingress/egress rules; no hardcoded real AMIs.
- **IAM** (floci): `aws_iam_role` + `aws_iam_role_policy_attachment`; policies via `data "aws_iam_policy_document"`.
- **EKS** (floci): real k3s containers; toggle to mock via `FLOCI_SERVICES_EKS_MOCK=true` if Docker socket access is restricted.
- **VPC** (ministack): always align CIDRs with `docs/subnet.csv`.

### VPC naming and AWS VPC endpoints (`vpc-base`)

- **Prod VPC names in tfvars**: peering and PrivateLink VPC **Name** tags come from `peering_*_vpc_name` and `pl_*_vpc_name` in `environments/prod`. TGW hub **Name** tags use `tgw_name_tag_region_*`; spoke VPC names remain **map keys** in `tgw_spokes_region_*`. Inventory table: [docs/README.md](docs/README.md) **§1.3**.
- **Naming and diagrams**: use [docs/README.md](docs/README.md) **§1.2 *Network conventions*** for landing zone vs spoke, VPC naming table, and Gateway vs Interface endpoint diagrams.
- **Endpoints in code**: `modules/networking/vpc` exposes optional flags: **S3 Gateway** (app + data route tables), **KMS / STS Interface** (app subnets, dedicated SG for TCP 443 from the VPC CIDR, `private_dns_enabled = true`). Endpoints live in ministack `:4567` like the rest of VPC primitives.
- **Tagging**: new endpoint and SG resources must use `merge(local.default_tags, { Name = ... })` like other `vpc-base` resources.
- **Conventions drift**: when you introduce new lab-wide naming rules, update **this file** and the long-form README §1.2 together.

---

## Emulation compatibility (summary)

| Capability | Backed by | Notes |
|---|---|---|
| EC2 / VPC core | ministack `:4567` | Full (136 actions) |
| VPC peering | ministack | ✅ |
| Transit Gateway | ministack | ❌ — not implemented |
| PrivateLink (VPC Endpoint Service) | ministack | ❌ — not implemented |
| VPC Endpoints (Gateway + Interface) | ministack | ✅ |
| NACL / Flow Logs / Egress-only IGW | ministack | ✅ |
| ELBv2 / ALB / NLB | ministack | ✅ |
| WAF v2 | ministack | ✅ |
| IAM | floci `:4566` | Optional policy enforcement |
| STS | floci | All 7 ops |
| S3 | floci | Full + Object Lock |
| SNS / SQS / KMS | floci | Cross-account topic/queue policies stored, not enforced |
| EKS | floci | Real k3s clusters (default) or mock |
| Lambda / ECS / ECR / RDS / ElastiCache / MSK | floci | Real Docker containers |
| Terraform provider >= 6.0 | both | ✅ |

**Module toggles in `environments/prod/terraform.tfvars`:**
- `enable_transit_gateway = false`
- `enable_privatelink = false`
- `enable_tgw_cross_region_peering = false`
- `enable_waf = false`

When behavior differs from AWS:

```hcl
# NOTE: Emulator limitation — what differs and why this resource is still useful
```

---

## Code style and security

- 2-space indentation; `snake_case` for Terraform names.
- No secrets in `.tf` or `terraform.tfvars`; keep `.tfstate` ignored.

### Pre-push checklist

Run before every `git push`:

```bash
terraform fmt -check -recursive
trivy config --severity HIGH,CRITICAL iam/
trivy config --severity HIGH,CRITICAL environments/
```

All commands must pass with 0 findings.

### Commit messages

- AI agents must not add `Signed-off-by`, `Co-authored-by`, `Assisted-by`, or any other attribution trailers.
- Limit the subject to 50 characters, start with a capital letter, do not end with a period.
- Explain what and why in the body, if more than a trivial change; wrap at 72 characters.
- Use the imperative mood ("Add support for X", not "Added"/"Adds").
- Do not include GitHub mentions to issues or accounts in the commit message — use the PR description.

### Resource tagging (AWS) — always apply

When adding or editing Terraform under `modules/`, follow the same pattern as existing modules:

- In each module, define `local.module_label = basename(abspath(path.module))` and `local.default_tags = merge(var.tags, { TerraformModule = local.module_label })`.
- Use `merge(local.default_tags, { Name = ... })` on resources that support `tags`. **Do not** hardcode the module name in `TerraformModule`; always derive it with `basename(abspath(path.module))`.
- New modules must include this `locals` block and pass `var.tags` from the root.
- Root environments continue to set `default_tags` on the `aws` provider for `Project`, `Environment`, `ManagedBy`; do not duplicate those keys per resource unless your change requires an override.

---

## Container runtime

This lab uses **Podman** (preferred) or Docker as fallback. Scripts auto-detect `podman-compose` → `podman compose` → `docker compose`.

Images:
- `floci/floci:latest` (port 4566)
- `ministackorg/ministack:latest` (published on host 4567)

Both bind-mount `/var/run/docker.sock` because floci's EKS/Lambda/EC2/ECS services launch real Docker containers, and ministack uses the socket for its own runtime as well.

---

## Linting (tflint)

Run **after any Terraform change** (modules or `environments/*` / `iam/*`) and before pushing; CI uses the same rules via `.tflint.hcl`.

```bash
which tflint || echo "tflint not installed"
tflint --init
tflint --recursive
```

---

## Clarification-first

If the target (`dev` vs `prod` vs which `iam/*` root) is unclear, ask one short question before coding.

## Strictly avoid

- Renaming/moving resources between modules unless asked.
- Inventing CIDRs without `docs/subnet.csv`.
- Manual state file edits.
- Unrelated large diffs.
- Pointing networking endpoints at floci or compute/identity endpoints at ministack — keep the split documented above.

---

## Docs

- [docs/README.md](docs/README.md) — includes **§1.1** (tagging), **§1.2** (landing zone vs spoke, endpoints), **§1.3** (prod VPC inventory / tfvars map)
- [docs/support.md](docs/support.md) — combined API coverage matrix (floci + ministack) and workarounds
