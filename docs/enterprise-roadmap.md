# Enterprise Roadmap — mở rộng nâng cao

> Những mảng "enterprise-grade" nên học/mở rộng **sau** khi xong core (Phase 0–5). Mỗi mục ghi rõ floci có chạy được không + độ ưu tiên học. Đây là bản nhắc, chưa scaffold.

Cột floci: ✅ apply được · ⚠️ một phần · ❌ chưa hỗ trợ (xem `docs/floci-unsupported.md`) · ☁️ chỉ AWS thật.

## 1. Multi-account / Landing Zone
| Chủ đề | floci | Ưu tiên | Ghi chú |
|---|---|---|---|
| AWS Organizations, OU, **SCP** (guardrail) | ☁️ | ★★★ | SCP = ranh giới quyền tối đa toàn account; học bằng JSON policy + plan |
| Control Tower / landing zone baseline | ☁️ | ★★ | Khái niệm: management / log-archive / audit / shared-services |
| Account vending (Terraform tạo account) | ☁️ | ★ | `aws_organizations_account` |
| **Cross-account assume-role** chuẩn (thay access-key-per-account của lab) | ⚠️ | ★★★ | Lab mô phỏng bằng access key; AWS thật dùng `assume_role` + external_id |

## 2. Networking nâng cao
| Chủ đề | floci | Ưu tiên | Ghi chú |
|---|---|---|---|
| **Transit Gateway** hub-spoke | ❌ | ★★★ | Viết module để học, validate-only |
| **Shared VPC** qua RAM (`aws_ram_resource_share`) | ☁️ | ★★ | Network account share subnet cho workload account |
| Centralized **egress** (NAT tập trung) + inspection | ☁️ | ★★ | Giảm chi phí NAT toàn org |
| Route53 **Resolver** (inbound/outbound, forwarding rules) | ⚠️ | ★★ | DNS hybrid/cross-VPC |
| **Network Firewall** / AWS Firewall Manager | ☁️ | ★ | |
| PrivateLink (VPC Endpoint Service) | ❌ | ★★ | validate-only |

## 3. Identity & Access
| Chủ đề | floci | Ưu tiên | Ghi chú |
|---|---|---|---|
| **IAM Identity Center (SSO)** + permission sets | ☁️ | ★★★ | Thay IAM user; gán theo account/OU |
| **Permissions boundary** + path chuẩn hoá | ✅ | ★★★ | Đã đưa vào module `security/iam-role` |
| **ABAC** (tag-based access control) | ⚠️ | ★★ | Condition theo tag `aws:PrincipalTag` |
| EKS **Pod Identity** (đã chọn thay IRSA) | ⏳ | ★★★ | Phase 4 |

## 4. State, CI/CD, delivery
| Chủ đề | floci | Ưu tiên | Ghi chú |
|---|---|---|---|
| Remote backend per-account (S3 + lock) | ⚠️ | ★★★ | floci S3 ✅; lock dùng S3 native lockfile (TF 1.10+) hoặc DynamoDB |
| **OIDC GitHub Actions → AWS** (không long-lived key) | ☁️ | ★★★ | `aws_iam_openid_connect_provider` cho token.actions.githubusercontent.com |
| Plan/apply tách biệt + artifact + approval | n/a | ★★★ | CI matrix theo account/env/component |
| Terragrunt **hoặc** TF Stacks (khi >10 root) | n/a | ★★ | Hiện dùng plain Terraform roots (chưa cần Terragrunt) |
| Drift detection (scheduled plan) | n/a | ★★ | |

## 5. Security & compliance
| Chủ đề | floci | Ưu tiên | Ghi chú |
|---|---|---|---|
| Policy-as-code gate: **Checkov / Trivy / tflint** | n/a | ★★★ | Đã có; mở rộng custom rule |
| OPA/Conftest hoặc Sentinel | n/a | ★★ | Gate nâng cao trong CI |
| GuardDuty / Security Hub / AWS Config rules | ☁️ | ★★ | Org-wide detective controls |
| CloudTrail **org trail** → s3-logs | ⚠️ | ★★★ | Audit tập trung ở shared-services |
| Secrets Manager **rotation** + KMS multi-region | ⚠️ | ★★ | |

## 6. Observability & cost
| Chủ đề | floci | Ưu tiên | Ghi chú |
|---|---|---|---|
| Centralized logging (s3-logs + CloudWatch cross-account) | ⚠️ | ★★ | Gắn với module `data/s3-logs` |
| Budgets + Cost Categories + tag policy | ☁️ | ★★ | Có MCP billing để thực hành phân tích |
| OpenTelemetry / Container Insights | ⚠️ | ★ | |

## 7. EKS / compute nâng cao
| Chủ đề | floci | Ưu tiên | Ghi chú |
|---|---|---|---|
| **Karpenter** autoscaling | ⚠️ | ★★★ | Sau khi cluster chạy |
| Addons qua Pod Identity (vpc-cni, ebs-csi) | ⏳ | ★★ | |
| Private cluster (endpoint private only) | ⚠️ | ★★ | |
| Gateway API / NetworkPolicy / Cilium | ⚠️ | ★ | |
| ECS service connect / blue-green (CodeDeploy) | ⚠️ | ★ | |

## 8. Resilience
Multi-AZ (đã có per-AZ NAT toggle) · multi-region active/passive · DR runbook · backup (AWS Backup) — phần lớn ☁️/⚠️, học bằng code + plan.

---
**Cách dùng file này**: mỗi khi xong 1 mảng core, chọn 1–2 mục ★★★ ở đây để mở rộng. Mục ❌/☁️ học qua `validate`/`plan` + đọc, apply khi lên AWS thật.
