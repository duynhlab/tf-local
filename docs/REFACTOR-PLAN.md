# Refactor Plan — tf-local (learn TF + AWS, production-shaped)

> Trạng thái: **PROPOSAL — chờ duyệt**. Chưa refactor code hạ tầng. File này là bản kế hoạch để review.
> Ngày: 2026-06-24.

## 0. Quyết định đã chốt (từ Q&A)

| Chủ đề | Chốt |
|---|---|
| Trường phái module | **Hybrid lệch tự-viết**: tự viết VPC, Security Group, IAM, Pod Identity (KHÔNG IRSA), WAFv2, S3, KMS, SSM, ECR, ECS. **Bọc community** chỉ cho **EKS** (`terraform-aws-modules/eks`). **RDS: bỏ.** |
| Mỗi module | Deep-dive feature "hay dùng" qua context7 (đã research, xem §4). |
| Account model | **Multi-account** mô phỏng trên floci bằng `AWS_ACCESS_KEY_ID` = 12 chữ số: `dev/uat/prod` + 1 account **shared-services**. |
| Shared services | **CÓ LÀM** — ECR, s3-logs, kms-keys, ssm-parameters đặt ở account shared-services, chia sẻ cross-account. |
| Layout | `envs/{dev,uat,prod}` + `shared-services` (đã bỏ wrapper `live/`). |
| Emulator | **floci only** (+ floci-ui) — **bỏ hẳn ministack**. floci `1.5.27`, floci-ui `0.1.0`, Real Docker Integration (`user: root`), Override images. Feature floci chưa hỗ trợ → toggle-off + document (xem §7). |
| IRSA vs Pod Identity | **Giữ 1 bản IRSA legacy** (đánh dấu `_legacy`) để tham khảo **+ thêm bản Pod Identity mới**. |
| Region lab | `ap-southeast-1` (mặc định). |
| Naming | Theo **[docs/naming-conventions.md](naming-conventions.md)** (snake_case HCL, kebab-case folder/AWS name, prefix `dnl-<env>-…`). Áp dụng mọi module/root. |
| Feature floci thiếu | 4 toggle off: `enable_ipv6=false`, `enable_flow_logs=false`, peering chưa dùng, `enable_transit_gateway=false`. Chi tiết **[docs/floci-unsupported.md](floci-unsupported.md)**. |
| Mở rộng enterprise | Lộ trình ở **[docs/enterprise-roadmap.md](enterprise-roadmap.md)** (làm sau core). |
| Phạm vi | Refactor thực hiện theo phase ở §8. |

**Tài liệu liên quan**: [naming-conventions.md](naming-conventions.md) · [floci-unsupported.md](floci-unsupported.md) · [enterprise-roadmap.md](enterprise-roadmap.md)

---

## 1. Vấn đề hiện tại (nguồn gốc "rối")

1. **3–4 layout chồng nhau**: `environments/` (deprecated) + `envs/*` + `envs/*` + `iam/*` (13 thư mục phẳng ở root).
2. **`iam/` trộn 2 loại khác bản chất**: `iam/prod`, `iam/stg` (giống env thật) nằm cạnh `iam/cross-account`, `iam/s3-events`… (thực ra là **case-study/bài học**).
3. **Module trùng**: `modules/vpc-base` vs `modules/networking/vpc`.
4. **IRSA cũ**: `iam/prod` dùng `aws_iam_openid_connect_provider` (IRSA) — cái bạn muốn bỏ, chuyển sang **Pod Identity**.
5. **`environments/dev|prod/terraform.tfvars` bị git track** dù `.gitignore` đã loại (track từ trước). State thì OK (đã ignore).

---

## 2. Cấu trúc đích (target tree)

```
tf-local/
├── docker-compose.yml          # floci (pin) + floci-ui + ministack(optional profile)
├── bootstrap/                  # tạo S3 state bucket (giữ nguyên vai trò)
├── modules/                    # reusable, KHÔNG dính env
│   ├── networking/
│   │   ├── vpc/                # tự viết (nâng cấp từ networking/vpc hiện có)
│   │   ├── security-group/     # MỚI — pattern rule tách rời
│   │   ├── vpc-peering/        # move từ modules/vpc-peering
│   │   ├── transit-gateway/    # move (floci gap — xem §7)
│   │   └── privatelink/        # move (floci gap — xem §7)
│   ├── security/
│   │   ├── iam-role/           # MỚI — role + policy + attachment
│   │   ├── pod-identity/       # MỚI — thay IRSA
│   │   └── wafv2/              # move+nâng cấp từ modules/waf-v2
│   ├── data/
│   │   ├── s3-bucket/          # MỚI — split sub-resources
│   │   ├── s3-logs/            # MỚI — log-archive variant
│   │   ├── kms-key/            # MỚI
│   │   └── ssm-parameter/      # MỚI
│   ├── compute/
│   │   ├── ecs-service/        # MỚI — Fargate tự viết
│   │   ├── eks/                # MỚI — wrapper terraform-aws-modules/eks
│   │   └── ecr/               # MỚI
│   ├── messaging/
│   │   └── sqs-with-dlq/       # move từ modules/iam/sqs_with_dlq
│   ├── _legacy/
│   │   └── irsa-role/          # move từ modules/iam/irsa_role (giữ cho examples cũ)
│   └── lab-provider/           # giữ + mở rộng cho multi-account (access key theo account)
├── envs/
│   ├── dev/<region>/{networking, ecs, ...}/   # 111111111111
│   ├── uat/<region>/{...}/                     # 222222222222
│   └── prod/<region>/{...}/                    # 333333333333
├── shared-services/<region>/{ecr, s3-logs, kms, ssm}/   # account 100000000000
├── examples/
│   ├── networking/minimal/     # giữ
│   └── iam/                     # GOM toàn bộ iam/* case-study vào đây
│       ├── cross-account-sns-sqs/   (từ iam/prod, iam/stg — gộp, bỏ IRSA→Pod Identity hoặc đánh dấu legacy)
│       ├── alb-controller/  cluster-access/  cross-account/  cross-account-secrets/
│       ├── cross-region-pipeline/  cross-region-s3/  external-dns-cross-account/
│       ├── s3-eks/  s3-events/  s3-go-compute-matrix/  storage-drivers/
├── policies/  tests/  scripts/  docs/
```

`<region>` = `ap-southeast-1` (mặc định lab).

---

## 3. Mô hình multi-account trên floci

floci: nếu `AWS_ACCESS_KEY_ID` đúng **12 chữ số** → dùng làm **account ID**, resource cô lập giữa account. Tận dụng để học cross-account thật:

| Account | ID (access_key) | Vai trò |
|---|---|---|
| shared-services | `100000000000` | ECR, s3-logs tập trung, KMS keys, SSM params dùng chung |
| dev | `111111111111` | workload dev |
| uat | `222222222222` | workload uat |
| prod | `333333333333` | workload prod |

- Mỗi root set `provider "aws" { access_key = <id account>, secret_key = "test" }`.
- **Cross-account** (vd dev pull ECR ở shared-services): dùng **provider alias** thứ 2 với `access_key` của account kia + resource policy (ECR repo policy, KMS key policy, SSM-via-role). 
- ⚠️ Khác AWS thật: AWS thật dùng `assume_role`; lab dùng access-key-per-account để mô phỏng. providers.tf sẽ để sẵn block `assume_role` (comment) để sau chuyển sang AWS thật dễ.

---

## 4. Catalog module + feature spec (đã research qua context7)

> Mỗi module theo layout chuẩn `main.tf / variables.tf / outputs.tf / versions.tf`, có `local.default_tags` theo AGENTS.md.

### 4.1 networking/vpc (tự viết — nâng cấp)
Resources: `aws_vpc`, `aws_vpc_ipv4_cidr_block_association` (secondary CIDR), `aws_subnet` (public/app/data × AZ), `aws_internet_gateway`, `aws_eip`+`aws_nat_gateway`, `aws_egress_only_internet_gateway` (IPv6, optional), route table/route/association, `aws_vpc_endpoint` (gateway S3/DynamoDB + interface KMS/STS/ECR/logs), `aws_network_acl`(+rule), `aws_flow_log`(+CW log group/role).
Knobs chính: `enable_dns_hostnames/support`, `secondary_cidr_blocks`, per-tier subnet CIDR lists, **single_nat_gateway vs one_nat_gateway_per_az** (cost↔HA), `enable_ipv6`, `enable_flow_logs`+destination(cw/s3)+traffic_type+retention, `gateway_endpoints=[...]`+`interface_endpoints=[...]`, `manage_default_*`, per-tier subnet tags (EKS `kubernetes.io/role/elb`).
Outputs: `vpc_id`, `vpc_cidr_block`, `public/app/data_subnet_ids`, `nat_gateway_ips`, route table ids, `default_security_group_id`.

### 4.2 networking/security-group (MỚI)
Pattern **rule tách rời** (khuyến nghị của provider): `aws_security_group` (vỏ) + `aws_vpc_security_group_ingress_rule` / `egress_rule` (1 rule/resource, drive bằng `for_each`). Tránh inline block (gây replace cả SG). Mỗi rule: đúng 1 nguồn (`cidr_ipv4`|`cidr_ipv6`|`referenced_security_group_id`|`prefix_list_id`) + `from_port`/`to_port`/`ip_protocol`(`tcp|udp|icmp|-1`)+`description`+`tags`. Var: `ingress_rules`/`egress_rules` map(object).

### 4.3 security/iam-role (MỚI)
`data aws_iam_policy_document` (trust) + `aws_iam_role` + `aws_iam_policy` + `aws_iam_role_policy_attachment` (for_each managed ARNs). Knobs: `assume_role_policy`, `permissions_boundary`, `path`, `max_session_duration`, `force_detach_policies`, `tags`. Tránh `managed_policy_arns` (deprecated).

### 4.4 security/pod-identity (MỚI — thay IRSA)
`aws_iam_role` (trust principal = **Service `pods.eks.amazonaws.com`**, actions `sts:AssumeRole`+**`sts:TagSession`**) + `aws_iam_role_policy_attachment` + `aws_eks_pod_identity_association` (`cluster_name`/`namespace`/`service_account`/`role_arn`, for_each map bindings). Root cài addon `eks-pod-identity-agent`. **Không** OIDC provider, không `:sub/:aud` conditions; 1 role tái dùng nhiều cluster.

### 4.5 security/wafv2 (move + nâng cấp)
`aws_wafv2_web_acl` (+`visibility_config` bắt buộc ở ACL & mỗi rule), `aws_wafv2_ip_set`, `aws_wafv2_web_acl_association` (REGIONAL→ALB/APIGW), `aws_wafv2_web_acl_logging_configuration` (+`aws_cloudwatch_log_group` tên `aws-waf-logs-*`). Feature: **managed rule groups** (`AWSManagedRulesCommonRuleSet`, `KnownBadInputs`, `AmazonIpReputationList`, `SQLiRuleSet`...), **rate-based rule** (`limit`,`aggregate_key_type`), IP allow/block, `scope=REGIONAL|CLOUDFRONT`. Drive rules bằng `for_each` map.

### 4.6 data/s3-bucket (MỚI)
Split model (KHÔNG inline trên `aws_s3_bucket`): base + `ownership_controls`(`BucketOwnerEnforced`) + `public_access_block`(4 cờ true) + `server_side_encryption_configuration`(aws:kms + `bucket_key_enabled` hoặc AES256) + `versioning` + `lifecycle_configuration` + `logging`(trỏ s3-logs) + `bucket_policy`(deny non-TLS). 

### 4.7 data/s3-logs (MỚI — variant log-archive)
Khác s3-bucket: **bucket policy cho log writer** theo nguồn (S3 access logs→`logging.s3.amazonaws.com`; ALB→`logdelivery.elasticloadbalancing` / `aws_elb_service_account`; CloudTrail→`cloudtrail.amazonaws.com`; CloudFront cần ACL). Lifecycle archive (IA→GLACIER→DEEP_ARCHIVE→expire), versioning on, SSE thường AES256.

### 4.8 data/kms-key (MỚI)
`aws_kms_key`+`aws_kms_alias`+`aws_kms_key_policy`(+`aws_kms_grant` optional). Knobs: `enable_key_rotation=true`, `deletion_window_in_days`, `multi_region`. Key policy bắt buộc: root `kms:*`, key-admins, key-users; **cross-account**: statement principal `arn:...:<other-acct>:root` cho use-actions (consumer cần IAM policy khớp).

### 4.9 data/ssm-parameter (MỚI)
`aws_ssm_parameter` (for_each map bulk). Knobs: `type` (String/StringList/**SecureString**), `key_id` (CMK cho SecureString), `tier`, path `/<env>/<app>/<key>`. **Cross-account read**: qua IAM role assumable (`ssm:GetParameter*`+`kms:Decrypt`). ⚠️ value SecureString nằm **plaintext trong state** — note.

### 4.10 compute/ecr (MỚI)
`aws_ecr_repository`(+`image_tag_mutability=IMMUTABLE`, `scan_on_push=true`, encryption AES256/KMS) + `aws_ecr_lifecycle_policy` (giữ N tag, expire untagged>14d) + `aws_ecr_repository_policy` (cross-account pull: `GetDownloadUrlForLayer`,`BatchGetImage`,`BatchCheckLayerAvailability`; consumer cần `GetAuthorizationToken` ở IAM riêng).

### 4.11 compute/ecs-service (tự viết — Fargate)
`aws_ecs_cluster`(+containerInsights)+`aws_ecs_cluster_capacity_providers`(FARGATE+FARGATE_SPOT)+`aws_ecs_task_definition`(`awsvpc`,`requires_compatibilities=["FARGATE"]`)+`aws_ecs_service`+2 IAM role (**execution** attach `AmazonECSTaskExecutionRolePolicy`; **task** app-scoped)+`aws_cloudwatch_log_group`+`aws_lb_target_group`/`listener`(`target_type=ip`)+`aws_appautoscaling_target`/`policy`. Knobs: cpu/memory, container_definitions, desired_count, exec/task role, subnets/sg/assign_public_ip, ALB(tg/container/port), capacity_provider_strategy(spot mix), autoscaling(CPU/Mem target), `deployment_circuit_breaker{rollback}`, `enable_execute_command`.

### 4.12 compute/eks (wrapper community)
`source=terraform-aws-modules/eks/aws`, **pin `= 21.0.x`** (v21 đổi tên: `name`/`kubernetes_version`/`addons`/`endpoint_public_access`; mặc định `authentication_mode="API"`). Wrapper expose: `name`,`kubernetes_version`,`vpc_id`,`subnet_ids`,`control_plane_subnet_ids`,`endpoint_*_access`,`enable_cluster_creator_admin_permissions`,`eks_managed_node_groups`,`addons`,`access_entries`,`tags`. addons: `coredns`,`kube-proxy`,`vpc-cni{before_compute}`,**`eks-pod-identity-agent{before_compute}`**. Pod Identity: addon bật ở đây + `aws_eks_pod_identity_association` cho app workload (qua module security/pod-identity, tách khỏi cluster lifecycle).

---

## 5. Mapping file cũ → mới

| Hiện tại | Hành động |
|---|---|
| `environments/dev`, `environments/prod` | **DELETE** (đã deprecated) + `git rm --cached` 2 file `terraform.tfvars` |
| `envs/{dev,prod}/networking` | **MOVE** → `envs/{dev,prod}/ap-southeast-1/networking` (provider floci) |
| `envs/{dev,prod}/.../networking` | **GỘP** vào `envs/*` (giữ block backend s3 + assume_role dạng comment làm tham khảo AWS thật) |
| `envs/uat` | **MỚI** |
| `shared-services/...` | **MỚI** |
| `iam/prod`, `iam/stg` | **MOVE+GỘP** → `examples/iam/cross-account-sns-sqs` (giữ bản IRSA `_legacy` + thêm `cross-account-sns-sqs-pod-identity`) |
| `iam/{alb-controller,cluster-access,cross-account,cross-account-secrets,cross-region-pipeline,cross-region-s3,external-dns-cross-account,s3-eks,s3-events,s3-go-compute-matrix,storage-drivers}` | **MOVE** → `examples/iam/<name>` |
| `modules/vpc-base` | **DELETE** (trùng `networking/vpc`) |
| `modules/waf-v2` | **MOVE** → `modules/security/wafv2` + nâng cấp |
| `modules/vpc-peering`, `modules/transit-gateway`, `modules/privatelink` | **MOVE** → `modules/networking/*` |
| `modules/iam/sqs_with_dlq` | **MOVE** → `modules/messaging/sqs-with-dlq` |
| `modules/iam/irsa_role` | **MOVE** → `modules/_legacy/irsa-role` (giữ cho examples cũ) |
| `modules/networking/vpc` | **GIỮ** + nâng cấp (flow logs, NACL, thêm endpoints, per-AZ NAT, IPv6 optional) |
| `modules/lab-provider` | **GIỮ** + thêm map access-key theo account |

⚠️ Khi đổi `source` của module trong root đang có state → dùng `moved {}` block nếu giữ state; với lab state là disposable (local, gitignored) nên có thể destroy→re-apply.

---

## 6. docker-compose — thay đổi

1. **Pin floci**: `image: docker.io/floci/floci:<tag-stable-mới-nhất>` — Phase 0 dò registry/releases lấy tag stable mới nhất rồi pin cứng (không dùng `latest`).
2. **Real Docker Integration**: thêm `user: "root"` (đã có mount `/var/run/docker.sock`).
3. **Override default images** (block env có comment để bật khi cần):
   `FLOCI_SERVICES_RDS_DEFAULT_POSTGRES_IMAGE`, `..._MYSQL_IMAGE`, `FLOCI_SERVICES_ELASTICACHE_DEFAULT_IMAGE`, `FLOCI_SERVICES_MSK_DEFAULT_IMAGE`, `FLOCI_SERVICES_NEPTUNE_DEFAULT_IMAGE`, `FLOCI_ECR_BASE_URI`.
4. **floci-ui** (service mới): `image: floci/floci-ui:<tag-stable-mới-nhất>`, `ports: ["4500:4500"]` (+API `4501` nếu cần), env `FLOCI_ENDPOINT=http://floci:4566`, `AWS_REGION=ap-southeast-1`, `AWS_ACCESS_KEY_ID/SECRET=test`, `depends_on: floci(healthy)`. Truy cập http://localhost:4500.
5. **Multi-account**: access key per account đến từ Terraform provider (không phải compose) — chỉ ghi chú trong README.
6. **ministack**: **gỡ bỏ hoàn toàn** (service + volume). Phase 1 dọn nốt tham chiếu còn lại: `modules/lab-provider/common.tf` (viết lại floci-only), `scripts/validate-ministack-apis.sh` (xoá), `scripts/{setup,teardown}.sh`, `AGENTS.md`, `README.md`.

---

## 7. floci GAPS matrix (cần verify trước khi bỏ ministack)

| ID | Hạng mục | Trạng thái | Ghi chú / hành động |
|---|---|---|---|
**Probe đã chạy 2026-06-24 trên floci 1.5.27 → 15 PASS / 4 FAIL.**

| ID | Hạng mục | Trạng thái | Ghi chú |
|---|---|---|---|
| GAP-1 | floci tag | ✅ `1.5.27` | Verified Docker Hub (release 2026-06-23). Pinned. Có biến thể `1.5.27-compat` (parity). |
| GAP-2 | floci-ui tag | ✅ `0.1.0` | Pinned, UI http://localhost:4500 (HTTP 200). |
| GAP-3a | VPC core: create-vpc, subnet, IGW, **NAT GW**, route-table, NACL | ✅ PASS | Dùng được bình thường trên floci. |
| GAP-3b | VPC endpoint **Gateway (S3)** | ✅ PASS | OK. Interface endpoint chưa probe riêng → test khi làm module. |
| GAP-3c | **Egress-only IGW** | ❌ `UnsupportedOperation` | IPv6 egress-only KHÔNG hỗ trợ → toggle `enable_ipv6=false`, module viết để học, validate-only. |
| GAP-3d | **VPC Flow Logs** | ❌ `UnsupportedOperation` | KHÔNG hỗ trợ → toggle `enable_flow_logs=false`; chỉ apply trên AWS thật. |
| GAP-3e | **VPC Peering** | ❌ `UnsupportedOperation` | KHÔNG hỗ trợ → module `vpc-peering` chỉ `validate`/`plan`, không apply. |
| GAP-4 | **ELBv2** (target group, describe-lb) | ✅ PASS | OK cho ECS/WAF association (ALB cần ≥2 subnet — test khi làm). |
| GAP-5 | **WAFv2** (ip-set, list-web-acls) | ✅ PASS | OK. Test association ALB khi làm module. |
| GAP-6 | **Transit Gateway** / PrivateLink | ❌ `UnsupportedOperation` (TGW) | Giữ toggle `enable_* = false`; module viết để học, validate-only. |
| GAP-7 | **KMS / SSM SecureString / ECR** | ✅ PASS | create-key, put SecureString, create-repository đều OK. |
| GAP-8 | EKS / Pod Identity | ⏳ chưa probe | Chạy `PROBE_EKS=1 ./scripts/probe-floci.sh` ở Phase 4. ServiceRegistry có `eks` → khả quan. |

**Kết luận**: floci phủ tốt VPC core + ELBv2 + WAFv2 + IAM/KMS/SSM/ECR + multi-account. **4 feature thiếu** (egress-only IGW, Flow Logs, VPC Peering, Transit Gateway) → các module liên quan vẫn **viết đầy đủ để học**, nhưng đặt **toggle mặc định off** và chỉ `validate/plan` (apply chỉ trên AWS thật). Không có fallback ministack.

---

## 8. Phasing (thứ tự + verify)

> Verify chung mỗi phase: `terraform fmt -check -recursive`, `terraform -chdir=<root> init/validate`, `tflint --recursive`, `trivy config`, `terraform test` (module smoke). Không apply lên AWS thật.

- **Phase 0 — Emulator & probe** → verify: floci+floci-ui chạy, bảng GAP §7 cập nhật ✅/❌, chốt floci-only vs hybrid.
  - Update docker-compose (pin, root, override env, floci-ui, ministack profile).
  - Chạy probe script → điền GAPS.
- **Phase 1 — Cleanup cấu trúc (ít rủi ro)** → verify: `terraform validate` mọi root còn lại pass, CI xanh.
  - `git rm --cached` 2 tfvars; xoá `environments/`, `modules/vpc-base`.
  - Gom `iam/*` → `examples/iam/*`; move modules vào nhóm (`networking/`,`security/`,`messaging/`,`_legacy/`).
  - Sửa path trong `scripts/*`, `.github/workflows/*`, `AGENTS.md`, `README.md`, `docs/*`.
- **Phase 2 — Core modules + shared-services** → verify: module tests + `shared-services` validate.
  - Modules: `security/iam-role`, `data/{s3-bucket,kms-key,ssm-parameter}`, `compute/ecr`.
  - Roots: `shared-services/<region>/{kms,s3-logs,ssm,ecr}` (account 100000000000).
- **Phase 3 — Networking + security per env** → verify: dev/uat/prod networking validate.
  - Modules: nâng cấp `networking/vpc`, `networking/security-group`, `security/wafv2`.
  - Roots: `envs/{dev,uat,prod}/<region>/{networking,security}`.
- **Phase 4 — Compute** → verify: ecs/eks roots validate, pod-identity associations plan OK.
  - Modules: `compute/ecs-service`, `compute/eks` (wrapper), `security/pod-identity`.
  - Roots: `envs/{dev,...}/<region>/{ecr,ecs,eks}` + cross-account pull ECR.
- **Phase 5 — Examples + docs** → verify: examples validate, docs nhất quán.
  - Chuyển case-study IAM sang Pod Identity (hoặc đánh dấu `_legacy`).
  - Cập nhật `docs/` (support matrix, module-versioning), `AGENTS.md`.

---

## 9. Risk controls (terrashark)

- **Identity churn**: đổi `source`/đường dẫn module → dùng `moved {}` nếu giữ state; lab state disposable nên ưu tiên destroy→re-apply, ghi rõ trong từng phase.
- **Secret exposure**: SSM SecureString để plaintext trong state (GAP đã note); không dùng secret thật; `.tfstate`/`terraform.tfvars` giữ trong `.gitignore`; gỡ 2 tfvars đang bị track.
- **Blast radius**: state tách theo `account × env × region × component`; mỗi root độc lập.
- **CI drift**: commit `.terraform.lock.hcl` mỗi root; CI matrix-validate; pin EKS module `= 21.0.x`, provider `~> 6.0`.
- **Compliance gates**: giữ checkov/trivy/tflint; thêm rule cho s3 public-access-block & ECR scan_on_push.

---

## 10. Quyết định đã chốt

1. ✅ **Account IDs**: `100000000000` (shared-services) / `111111111111` (dev) / `222222222222` (uat) / `333333333333` (prod).
2. ✅ **Region** lab: `ap-southeast-1` mặc định.
3. ✅ **examples/iam/cross-account-sns-sqs**: giữ bản **IRSA `_legacy`** để tham khảo **+ thêm bản Pod Identity** mới.
4. ✅ **ministack**: để dạng `profiles:[hybrid]` (floci-only mặc định); quyết định cuối sau probe Phase 0 (§7).
5. ✅ **floci / floci-ui tag**: tự dò tag stable mới nhất ở Phase 0 rồi pin cứng.

## 11. Tiến độ

- ✅ **Dọn rác**: xoá ~2.7GB cache `.terraform/` + toàn bộ state cũ emulator (repo 3.0G→6.3M).
- ✅ **Phase 0**: docker-compose floci-only (`floci:1.5.27` + `floci-ui:0.1.0` + real-docker + override-images), healthcheck `curl`, `scripts/probe-floci.sh` (15 PASS/4 FAIL). GAPS §7 đã điền.
- ✅ **Dead cleanup**: xoá `environments/`, `modules/vpc-base`, `scripts/validate-ministack-apis.sh`; `setup.sh`/`teardown.sh` floci-only.
- ✅ **Phase 1 — reorg + naming (DONE)**:
  1. ✅ `modules/lab-provider/common.tf` floci-only + `local.lab_accounts` (giữ tên map cũ → providers.tf không cần sửa).
  2. ✅ `iam/*` → `examples/iam/*` (kèm drawio/debug assets); `iam/prod`→`cross-account-sns-sqs`, `iam/stg`→`cross-account-sns-sqs-stg`.
  3. ✅ Module gom nhóm + đổi tên (waf-v2→security/wafv2, vpc-peering/transit-gateway/privatelink→networking/, sqs_with_dlq→messaging/, irsa_role→_legacy/).
  4. ✅ `live/lab`→`envs/{dev,uat,prod}/ap-southeast-1/networking` (multi-account access_key); `live/aws` xoá; `uat` mới; `shared-services` skeleton.
  5. ✅ `source` paths + symlink fix; `ci.yml` floci-only paths; `aws-ci.yml` xoá; `test-all.sh`/`setup.sh`/`teardown.sh` floci-only; `README.md` rewrite; `AGENTS.md` mục chính.
  6. ✅ Verify: `fmt` sạch; dev/uat/prod + examples `validate` Success.
  - ⏳ Doc polish còn lại (non-breaking): AGENTS bảng limitations/compat, `docs/support.md`, `docs/README.md`, README các example/module, `bootstrap/README.md`, `docs/{landing-zone,module-versioning}.md`.
- ✅ **Phase 2 — core modules + shared-services (DONE)**: modules `security/iam-role`, `data/{s3-bucket,s3-logs,kms-key,ssm-parameter}`, `compute/ecr` (hand-written, context7-researched). Roots `shared-services/ap-southeast-1/{kms,s3-logs,ssm,ecr}` (account 100000000000, cross-account grants to dev/uat/prod). Verified: all apply+destroy on floci; ARNs carry account 100000000000.
- ✅ **Phase 3-5 (DONE)**: modules `networking/security-group`, `compute/ecs-service`, `compute/eks` (wraps terraform-aws-modules/eks `21.0.6`), `security/pod-identity`. Roots `envs/dev/ap-southeast-1/{ecs,eks}` (cross-stack via `terraform_remote_state` of networking). Example `examples/iam/pod-identity-s3` (Pod Identity vs IRSA-legacy contrast). Verified: all validate; **dev networking→ecs apply end-to-end on floci** (cross-stack + SG + ECS). floci gap found: AWS-managed IAM policies not preloaded → modules use inline equivalents (documented).
