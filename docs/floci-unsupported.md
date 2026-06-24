# floci — Unsupported operations & re-check log

> Probe gần nhất: **2026-06-24, floci `1.5.27`** (`./scripts/probe-floci.sh`).
> floci-only (đã bỏ ministack). Khi floci release thêm → chạy lại probe & cập nhật bảng + bật toggle tương ứng.

## Không hỗ trợ (xác nhận `UnsupportedOperation`)

| AWS API action | TF resource bị ảnh hưởng | Quyết định (tạm) | Toggle / vị trí |
|---|---|---|---|
| `CreateEgressOnlyInternetGateway` | `aws_egress_only_internet_gateway` | **Disable IPv6 tạm thời** | `enable_ipv6 = false` (module `networking/vpc`) |
| `CreateFlowLogs` | `aws_flow_log` (+ log group/role) | **Chưa cần** | `enable_flow_logs = false` (module `networking/vpc`) |
| `CreateVpcPeeringConnection` | `aws_vpc_peering_connection*` | **Chưa cần / disable** | module `networking/vpc-peering` → chỉ `validate`/`plan`, không apply |
| `CreateTransitGateway` | `aws_ec2_transit_gateway*` | **Disable** | `enable_transit_gateway = false` (module `networking/transit-gateway`) |

## Chưa probe — giả định cần kiểm khi làm

| Hạng mục | Trạng thái | Khi nào kiểm |
|---|---|---|
| PrivateLink — `CreateVpcEndpointServiceConfiguration` | ⚠️ nhiều khả năng thiếu (cùng họ peering/TGW) | Phase 3, module `privatelink` → `enable_privatelink = false` |
| VPC **Interface** endpoint (KMS/STS/ECR) | ⚠️ chưa probe (Gateway S3 đã ✅) | Phase 3 khi thêm interface endpoints |
| EKS Pod Identity (`eks-pod-identity-agent` addon, `CreatePodIdentityAssociation`) | ⏳ chưa probe | Phase 4: `PROBE_EKS=1 ./scripts/probe-floci.sh` |
| KMS multi-account / aliased provider | ⏳ (single-account `CreateKey` đã ✅) | Phase 2 khi làm kms cross-account |

## Đã hỗ trợ tốt (apply được trên floci)

VPC core (vpc/subnet/IGW/**NAT GW**/route-table/NACL) · VPC endpoint **Gateway (S3)** · **ELBv2** (target group) · **WAFv2** (web ACL/IP set) · IAM/STS · **KMS** · **SSM SecureString** · **ECR** · **Multi-account isolation** (access key 12 số).

## Quy trình re-check khi floci ra bản mới

```bash
# 1. Bump tag trong docker-compose.yml (floci/floci:<new>) — kiểm Docker Hub trước
gh release list --repo floci-io/floci --limit 5
# 2. Up lại + probe
./scripts/setup.sh
./scripts/probe-floci.sh          # + PROBE_EKS=1 cho EKS
# 3. Action nào chuyển PASS → đổi ✅ ở bảng trên + bật toggle (enable_* = true) ở root tương ứng
```

> Các module của feature chưa hỗ trợ **vẫn được viết đầy đủ để học** (chạy `terraform validate`/`plan`), chỉ không `apply` trên floci. Khi lên AWS thật hoặc floci hỗ trợ → bật toggle là dùng được.
