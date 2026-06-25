# tf-local — Terraform + AWS learning lab (floci)

Lab học Terraform + AWS theo hướng **production-shaped**: multi-account, module tree 3 lớp, networking + IAM + compute + data — chạy hoàn toàn trên emulator **[floci](https://floci.io)** (không cần AWS thật).

## Emulator

| Service | Port | Vai trò |
|---|---|---|
| **floci** | `:4566` | 64 AWS services: IAM/STS, S3, KMS, SSM, ECR, ECS, EKS, EC2/VPC, ELBv2, WAFv2, SNS/SQS, Lambda… |
| **floci-ui** | `:4500` | Web console (Cloud Explorer) |

Multi-account: `AWS_ACCESS_KEY_ID` = 12 chữ số → floci coi là account id (resource cô lập). Lab dùng `shared 100000000000 / dev 111111111111 / uat 222222222222 / prod 333333333333`.

## Prerequisites
- Podman (ưu tiên) hoặc Docker + Compose
- Terraform >= 1.9
- AWS CLI v2

## Quick start
```bash
./scripts/setup.sh        # up floci + floci-ui, đợi healthy
# UI: http://localhost:4500
./scripts/probe-floci.sh  # kiểm tra độ phủ floci (GAPS matrix)
./scripts/test-all.sh     # fmt + validate mọi env + apply/destroy dev
./scripts/teardown.sh     # dừng (CONFIRM_DESTROY=1 để destroy roots trước)
```

## Cấu trúc

```
modules/                       # reusable (snake_case HCL, kebab-case folder)
  networking/  {vpc, vpc-peering, transit-gateway, privatelink}
  security/    {wafv2, ...}     # + iam-role, pod-identity (Phase 2-4)
  data/        {s3-bucket, s3-logs, kms-key, ssm-parameter}   (Phase 2)
  compute/     {ecs-service, eks, ecr}                        (Phase 2-4)
  messaging/   {sqs-with-dlq}
  _legacy/     {irsa-role}      # tham khảo; chuẩn mới = Pod Identity
  lab-provider/                 # floci endpoints + account map (symlink vào mỗi root)
envs/{dev,uat,prod}/ap-southeast-1/{networking,ecs,...}/    # workload accounts
shared-services/ap-southeast-1/{ecr,s3-logs,kms,ssm}/       # shared account
examples/
  networking/minimal/
  iam/                          # case-study IAM (cross-account, IRSA legacy, ...)
docs/  policies/  tests/  scripts/  bootstrap/
```

3 lớp: `envs/*` / `shared-services/*` (root mỏng) → `modules/<group>/*` (primitive/wrapper) → resource. Module style: **tự viết** VPC/IAM/WAFv2/S3/SG/ECS/Pod Identity; **bọc** community chỉ cho EKS; bỏ RDS.

## Tài liệu
- [docs/REFACTOR-PLAN.md](docs/REFACTOR-PLAN.md) — kế hoạch & tiến độ refactor (phases)
- [docs/naming-conventions.md](docs/naming-conventions.md) — chuẩn đặt tên
- [docs/floci-unsupported.md](docs/floci-unsupported.md) — feature floci chưa hỗ trợ + cách re-check
- [docs/enterprise-roadmap.md](docs/enterprise-roadmap.md) — mở rộng enterprise
- [AGENTS.md](AGENTS.md) — hướng dẫn cho AI agent + runbook

## floci chưa hỗ trợ (tính tới floci 1.5.27)
Egress-only IGW (IPv6), VPC Flow Logs, VPC Peering, Transit Gateway → module vẫn viết để học nhưng `validate`/`plan`-only (toggle off). Chi tiết + quy trình re-check: [docs/floci-unsupported.md](docs/floci-unsupported.md).
