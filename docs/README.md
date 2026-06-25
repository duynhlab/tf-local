# Architecture & docs index

Real, **copy-and-run-on-AWS** Terraform for a multi-account AWS platform. It is
developed and tested locally against the **floci** emulator (no real cloud spend),
but the code itself is plain real-AWS — no emulator config is committed.

- New here? Start with the root [`../README.md`](../README.md) (quick start) and
  [`../AGENTS.md`](../AGENTS.md) (canonical repo rules + runbook).
- This file = the **architecture overview + diagrams + docs map**.

## Docs map

| Doc | What it is |
|---|---|
| [naming-conventions.md](naming-conventions.md) | Naming standard (HCL, folders, AWS names, tags) |
| [floci-unsupported.md](floci-unsupported.md) | floci capability gaps + re-check runbook (single source of truth) |
| [connectivity-patterns.md](connectivity-patterns.md) | VPC Peering vs PrivateLink vs Transit Gateway (prod networking design) |
| [enterprise-roadmap.md](enterprise-roadmap.md) | Forward-looking enterprise backlog |
| [terragrunt-plan.md](terragrunt-plan.md) | Terragrunt adoption plan (planning only) |
| [REFACTOR-PLAN.md](REFACTOR-PLAN.md) | Architecture decisions + refactor history (done) |
| [subnet.csv](subnet.csv) | CIDR allocation (source of truth) |

---

## 1. Multi-account model

One account per environment plus a shared-services account. On real AWS the
account is selected by credentials / `assume_role`; on floci by a 12-digit
`AWS_ACCESS_KEY_ID` (floci isolates resources per access key).

```mermaid
flowchart TB
  subgraph shared["shared-services · 100000000000"]
    ecr[(ECR)]
    kms[(KMS keys)]
    logs[(S3 log-archive)]
    ssm[(SSM params)]
  end
  dev["dev · 111111111111"]
  uat["uat · 222222222222"]
  prod["prod · 333333333333"]
  shared -- "cross-account pull / grant" --> dev
  shared --> uat
  shared --> prod
```

## 2. Repo layers (3-layer model)

```mermaid
flowchart LR
  subgraph L1["modules/ — reusable, no env/account"]
    net[networking/*]
    sec[security/*]
    data[data/*]
    comp[compute/*]
    msg[messaging/*]
  end
  subgraph L2["envs/ & shared-services — root stacks (real provider + S3 backend)"]
    rdev[envs/dev/ap-southeast-1/*]
    ruat[envs/uat/...]
    rprod[envs/prod/...]
    rshared[envs/shared-services/...]
  end
  L1 -->|"module source"| L2
  rdev -.->|terraform_remote_state| rdev
```

Modules are provider-agnostic (no `provider` blocks). Each root under `envs/*`
is a standalone Terraform root with its own `providers.tf` + `backend.tf`.

## 3. dev ECS stack (the reference real workload)

`envs/dev/ap-southeast-1/networking` + `.../ecs`. The `ecs` root reads the
`networking` root's outputs via `terraform_remote_state` (S3).

```mermaid
flowchart LR
  user((Internet)) --> alb["ALB (public subnets)"]
  alb --> tg["Target group (target_type=ip)"]
  tg --> task["ECS Fargate task (app subnets)"]
  task -->|pull image| ecr[(ECR · shared-services)]
  task -->|logs| cw["CloudWatch /ecs/dnl-dev-app"]
  task -. "DB tier ready" .-> db[(RDS · data subnets)]
```

## 4. Network topology & security-group chain (per env)

3-tier VPC (`10.100.0.0/16` for dev), 1 subnet per tier per AZ. SG chain is
strict: internet → ALB → ECS → DB.

```mermaid
flowchart TB
  igw[IGW] --- pub
  subgraph vpc["VPC 10.100.0.0/16 (3 AZ)"]
    pub["public subnets — ALB, NAT GW"]
    app["app subnets — ECS tasks"]
    data["data subnets — RDS"]
    pub -->|NAT GW| app
  end
  net((Internet)) -->|"80/443"| albsg
  albsg["alb-sg"] -->|"app_port 8080"| ecssg["ecs-sg"]
  ecssg -->|"5432"| dbsg["db-sg"]
```

## 5. Module tree

```mermaid
flowchart TD
  M[modules/]
  M --> N[networking/]
  M --> S[security/]
  M --> D[data/]
  M --> C[compute/]
  M --> MS[messaging/]
  M --> L[_legacy/]
  N --> N1[vpc] & N2[security-group] & N3[alb] & N4[vpc-peering] & N5[transit-gateway] & N6[privatelink]
  S --> S1[iam-role] & S2[pod-identity] & S3[wafv2]
  D --> D1[s3-bucket] & D2[s3-logs] & D3[kms-key] & D4[ssm-parameter]
  C --> C1[ecr] & C2[ecs-service] & C3["eks (wraps terraform-aws-modules/eks 21.0.6)"]
  MS --> MS1[sqs-with-dlq]
  L --> L1["irsa-role (deprecated → use security/pod-identity)"]
```

## 6. Same code, two targets (floci vs real AWS)

The committed code is real AWS. Local testing only changes **environment + backend
config**, never the `.tf`.

```mermaid
flowchart LR
  root["a root (providers.tf + backend.tf)"]
  root -->|"AWS_ENDPOINT_URL + 12-digit AWS_ACCESS_KEY_ID<br/>backend.floci.hcl"| floci["floci :4566"]
  root -->|"AWS creds / assume_role<br/>backend.hcl"| aws["real AWS"]
```

State: S3 backend with **native locking** (`use_lockfile = true`, Terraform
≥ 1.11, no DynamoDB). Create the bucket once via
[`../scripts/bootstrap-state-bucket.sh`](../scripts/bootstrap-state-bucket.sh).

---

> floci capability gaps (peering, TGW, flow logs, egress-only IGW, gateway VPC
> endpoint, AWS-managed IAM policies, `assume_role` account isolation) and the
> re-check runbook live in **[floci-unsupported.md](floci-unsupported.md)**.
