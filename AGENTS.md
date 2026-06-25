# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor) working in this repository.

---

## Purpose

Production-shaped Terraform + AWS learning lab on a **floci-only** local emulator (ministack removed).

| Emulator | Host port | Role |
|---|---|---|
| **floci** | `:4566` | All 64 AWS services — IAM/STS, S3, KMS, SSM, ECR, ECS, EKS, EC2/VPC, ELBv2, WAFv2, SNS/SQS, Lambda, … |
| **floci-ui** | `:4500` | Web console (Cloud Explorer) |

Pinned `floci/floci:1.5.27` + `floci/floci-ui:0.1.0` in `docker-compose.yml` (Podman or Docker). Real Docker Integration enabled (`user: root` + docker.sock).

**Multi-account**: a 12-digit `AWS_ACCESS_KEY_ID` is treated by floci as the account id (resources isolate per account). Lab accounts: `shared 100000000000 / dev 111111111111 / uat 222222222222 / prod 333333333333` — see `modules/lab-provider/common.tf` (`local.lab_accounts`).

**Active plan**: this repo is mid-refactor. Read **[docs/REFACTOR-PLAN.md](docs/REFACTOR-PLAN.md)** (target structure, module catalog, phases) and **[docs/naming-conventions.md](docs/naming-conventions.md)** before adding code. Feature gaps: **[docs/floci-unsupported.md](docs/floci-unsupported.md)**.

---

## Lab scope

Use **`docs/subnet.csv`** for CIDRs. Intended learning areas:

- **Identity** (floci): IAM, STS, IRSA / Pod Identity patterns, optional **IAM policy enforcement** (`FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true`).
- **Data & edge** (floci): S3 + bucket policies / versioning / encryption / public access block (floci); WAF v2 (floci).
- **EC2 networking** (floci): VPC, subnets, IGW, NAT, egress-only IGW, route tables, VPC endpoints, peering (TGW / PrivateLink gated — see support matrix).
- **EC2 attachments** (floci): SGs, EIPs, ENIs, key pairs.
- **Core hardening** (floci): NACLs, Flow Logs, EBS.
- **Compute** (floci): EKS clusters via real k3s (mock mode available via `FLOCI_SERVICES_EKS_MOCK=true`), Lambda real runtimes, ECS, real EC2 containers.

Emulator capability gaps: **[docs/floci-unsupported.md](docs/floci-unsupported.md)**.

---

## Repository layout

```text
docker-compose.yml             # floci :4566 + floci-ui :4500
docs/
  REFACTOR-PLAN.md             # Target structure, module catalog, phases (read first)
  naming-conventions.md        # Naming standard (HCL snake_case, folders kebab-case)
  floci-unsupported.md         # floci feature gaps + re-check process
  enterprise-roadmap.md        # Advanced enterprise expansion backlog
  subnet.csv                   # CIDR source of truth
modules/                       # group/<module> ; snake_case HCL, kebab-case folders
  lab-provider/                # floci endpoints + lab_accounts map (symlinked per root)
  networking/  {vpc, vpc-peering, transit-gateway, privatelink}
  security/    {wafv2}         # + iam-role, pod-identity (Phase 2-4)
  data/        {...}           # s3-bucket, s3-logs, kms-key, ssm-parameter (Phase 2)
  compute/     {...}           # ecs-service, eks, ecr (Phase 2-4)
  messaging/   {sqs-with-dlq}
  _legacy/     {irsa-role}     # reference only; new standard = Pod Identity
envs/{dev,uat,prod}/ap-southeast-1/{networking,ecs,...}/   # workload accounts
shared-services/ap-southeast-1/{ecr,s3-logs,kms,ssm}/      # shared account 100000000000
examples/
  networking/minimal/
  iam/<scenario>/              # IAM case studies (cross-account, IRSA legacy, ...)
policies/checkov/              # Custom Checkov rules
tests/                         # terraform test (module smoke)
scripts/
  setup.sh                     # compose up floci + floci-ui
  teardown.sh                  # down -v (+ optional terraform destroy)
  test-all.sh                  # fmt + validate envs + apply/destroy dev
  probe-floci.sh               # floci capability probe (fills floci-unsupported.md)
.github/workflows/ci.yml       # fmt/validate/tflint/trivy/checkov/test + floci integration
```

Each directory under `envs/*` / `shared-services/*` and `examples/*` is a **standalone** Terraform root module.

---

## Runbook

1. **Start the emulator stack**

   ```bash
   ./scripts/setup.sh
   ```

   Auto-detects `podman-compose` → `podman compose` → `docker compose`. Podman is preferred.

2. **Health checks**

   ```bash
   curl -sf http://localhost:4566/_localstack/health  # floci
   curl -sf http://localhost:4500                     # floci-ui
   ./scripts/probe-floci.sh                           # capability probe
   ```

3. **Validate a networking root** (dev / uat / prod)

   ```bash
   ROOT=envs/dev/ap-southeast-1/networking
   terraform -chdir=$ROOT fmt -check
   terraform -chdir=$ROOT init -input=false
   terraform -chdir=$ROOT validate
   terraform -chdir=$ROOT apply -auto-approve   # dev fully applies on floci
   terraform -chdir=$ROOT output
   terraform -chdir=$ROOT destroy -auto-approve
   ```

4. **Validate examples** (validate-only; some need vars / floci-unsupported features)

   ```bash
   for d in examples/iam/*/; do
     terraform -chdir="$d" init -backend=false -input=false && \
     terraform -chdir="$d" validate
   done
   ```

5. **Stop**

   ```bash
   ./scripts/teardown.sh                # just stop containers
   CONFIRM_DESTROY=1 ./scripts/teardown.sh   # also destroy each root first
   ```

---

## Provider rules

- Shared locals live in [`modules/lab-provider/common.tf`](modules/lab-provider/common.tf); each root symlinks `lab_provider_common.tf` and references an endpoint map (`local.lab_hybrid_endpoints` or `local.lab_ministack_endpoints_*` — names kept for compat, **all point to floci `:4566`**) in `providers.tf`.

- All service endpoints → floci `http://localhost:4566`.

- Keep on the provider:
  - `skip_credentials_validation = true`
  - `skip_metadata_api_check     = true`
  - `skip_requesting_account_id  = true`
  - `access_key = local.lab_accounts.<env>` (12-digit account id) / `secret_key = "test"`
  - `s3_use_path_style = true`

- Never use real AWS credentials or real ARNs in lab code. The 12-digit access keys are floci account ids, not real accounts.

### `hashicorp/aws` version

- Use **`>= 6.0`**. floci is LocalStack-wire-compatible (port `4566`, parity layer); provider v6 works.
- **Commit** every root's `.terraform.lock.hcl` so CI resolves the same build.

---

## Known emulation limitations

Confirmed via `./scripts/probe-floci.sh` (floci 1.5.27). Authoritative list + re-check process: **[docs/floci-unsupported.md](docs/floci-unsupported.md)**.

| Resource / API | floci status | Workaround |
|---|---|---|
| `aws_egress_only_internet_gateway` | ❌ `UnsupportedOperation` | `enable_ipv6 = false` (module writes it; validate-only) |
| `aws_flow_log` | ❌ `UnsupportedOperation` | `enable_flow_logs = false` |
| `aws_vpc_peering_connection` | ❌ `UnsupportedOperation` | `vpc-peering` module: `validate`/`plan` only |
| `aws_ec2_transit_gateway` | ❌ `UnsupportedOperation` | `enable_transit_gateway = false` |
| `aws_vpc_endpoint_service` (PrivateLink) | ⚠️ likely unsupported | `enable_privatelink = false` (verify in Phase 3) |
| IAM policy enforcement | opt-in | `FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true` |
| EKS Pod Identity addon/association | ⏳ unprobed | `PROBE_EKS=1 ./scripts/probe-floci.sh` (Phase 4) |

---

## Allowed and disallowed Terraform commands

**Allowed:** `init`, `fmt`, `fmt -check`, `validate`, `plan`, `test`, `output`, `state list`, `state show <addr>`.

**Disallowed:** `import`, `state mv`, `state rm`, `state push`, `state pull`.

Use `apply` / `destroy` only for **local emulator** validation and document intent.

---

## Module selection

1. `modules/networking/vpc/` for VPC / subnet / route / IGW / NAT / VPC endpoint patterns.
2. Other `modules/*` when they fit.
3. Plain `resource` blocks only if no module fits.
4. External registry modules only when explicitly requested.

Do not add new providers or external modules without a clear request.

---

## Service-specific guidance

- **S3** (floci): `aws_s3_bucket` + separate `aws_s3_bucket_policy`; add versioning, encryption, public access block unless the exercise needs public access.
- **EC2** (floci): explicit SGs; prefer separate ingress/egress rules; no hardcoded real AMIs.
- **IAM** (floci): `aws_iam_role` + `aws_iam_role_policy_attachment`; policies via `data "aws_iam_policy_document"`.
- **EKS** (floci): real k3s containers; toggle to mock via `FLOCI_SERVICES_EKS_MOCK=true` if Docker socket access is restricted.
- **VPC** (floci): always align CIDRs with `docs/subnet.csv`.

### VPC naming and AWS VPC endpoints (`networking/vpc`)

- **Prod VPC names in tfvars**: peering and PrivateLink VPC **Name** tags come from `peering_*_vpc_name` and `pl_*_vpc_name` in `envs/prod/.../networking` tfvars. TGW hub **Name** tags use `tgw_name_tag_region_*`; spoke VPC names remain **map keys** in `tgw_spokes_region_*`. Inventory table: [docs/README.md](docs/README.md) **§1.3**.
- **Naming and diagrams**: use [docs/README.md](docs/README.md) **§1.2 *Network conventions*** for landing zone vs spoke, VPC naming table, and Gateway vs Interface endpoint diagrams.
- **Endpoints in code**: `modules/networking/vpc` exposes optional flags: **S3 Gateway** (app + data route tables), **KMS / STS Interface** (app subnets, dedicated SG for TCP 443 from the VPC CIDR, `private_dns_enabled = true`). Endpoints live on floci `:4566` like the rest of VPC primitives.
- **Tagging**: new endpoint and SG resources must use `merge(local.default_tags, { Name = ... })` like other `networking/vpc` resources.
- **Conventions drift**: when you introduce new lab-wide naming rules, update **this file** and the long-form README §1.2 together.

---

## Emulation compatibility (summary)

All on floci `:4566`. Probed 2026-06-24 (floci 1.5.27).

| Capability | floci | Notes |
|---|---|---|
| EC2 / VPC core (vpc, subnet, IGW, NAT, route table, NACL) | ✅ | apply works |
| VPC Endpoint — Gateway (S3) | ✅ | interface endpoints unprobed |
| VPC peering | ❌ | `UnsupportedOperation` — validate-only |
| Transit Gateway / PrivateLink | ❌ | `enable_* = false` |
| Flow Logs / Egress-only IGW (IPv6) | ❌ | `enable_flow_logs=false`, `enable_ipv6=false` |
| ELBv2 / ALB / NLB | ✅ | target group ok |
| WAFv2 | ✅ | web ACL / IP set ok |
| IAM / STS | ✅ | optional policy enforcement |
| S3 / KMS / SSM (SecureString) / ECR | ✅ | |
| SNS / SQS | ✅ | cross-account policies stored, not enforced |
| EKS | ✅ (probe Pod Identity in Phase 4) | real k3s or mock |
| Lambda / ECS | ✅ | real Docker containers |
| Multi-account isolation (12-digit key) | ✅ | |

Authoritative gaps + re-check: **[docs/floci-unsupported.md](docs/floci-unsupported.md)**.

**Module toggles in prod networking `terraform.tfvars`:**
- `enable_transit_gateway = false`
- `enable_privatelink = false`
- `enable_ipv6 = false`
- `enable_flow_logs = false`

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
trivy config --severity HIGH,CRITICAL examples/
trivy config --severity HIGH,CRITICAL envs/ shared-services/
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

Images (pinned):
- `floci/floci:1.5.27` (port 4566)
- `floci/floci-ui:0.1.0` (port 4500)

floci bind-mounts `/var/run/docker.sock` and runs as `root` (Real Docker Integration) because its EKS/Lambda/EC2/ECS/RDS services launch real Docker containers.

---

## Linting (tflint)

Run **after any Terraform change** (modules or `envs/*` / `shared-services/*` / `examples/*`) and before pushing; CI uses the same rules via `.tflint.hcl`.

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
- Pointing any service endpoint anywhere other than floci `:4566`.

---

## Docs

- [docs/README.md](docs/README.md) — includes **§1.1** (tagging), **§1.2** (landing zone vs spoke, endpoints), **§1.3** (prod VPC inventory / tfvars map)
- [docs/floci-unsupported.md](docs/floci-unsupported.md) — floci API gaps + re-check process
