# Local Emulator API Support Matrix

This lab targets a **hybrid stack** of two complementary AWS emulators:

| Emulator | Image | Host port | Health endpoint |
|---|---|---|---|
| **floci** | `floci/floci:latest` | `:4566` | `/_localstack/health` |
| **ministack** | `ministackorg/ministack:latest` | `:4567` | `/_ministack/health` |

The Terraform providers split their `endpoints { … }` block across the two emulators per service. The mapping (`environments/*/providers.tf`) is:

| Endpoint | Backed by |
|---|---|
| `ec2`, `elbv2`, `wafv2` | ministack `:4567` |
| `iam`, `sts`, `s3`, `kms` | floci `:4566` |

The `iam/*` roots point at `:4567` instead, because floci does not implement `aws_iam_openid_connect_provider` (IRSA), `aws_ebs_snapshot`, or `elbv2:DescribeCapacityReservation`, all of which the IRSA / storage / ALB-controller case studies need.

---

## Legend

| Symbol | Meaning |
|---|---|
| ✅ | Supported |
| ⚠️ | Partial / stub / stored-but-not-enforced |
| ❌ | Not implemented |

---

## Routing summary by service

| Service | floci `:4566` | ministack `:4567` | Used by |
|---|---|---|---|
| IAM | ✅ (+ optional enforcement) | ⚠️ stored | `iam/*`, providers |
| STS | ✅ | ✅ | providers |
| S3 | ✅ | ✅ | `iam/*`, S3 buckets |
| KMS | ✅ | ⚠️ aliased provider quirk | KMS keys, VPC KMS endpoint refs |
| SNS / SQS | ✅ | ✅ | `iam/*` |
| EKS | ✅ real k3s + tagging | ⚠️ partial | `iam/cluster-access`, `iam/alb-controller` |
| Lambda | ✅ real runtimes | ✅ | future case studies |
| ECS / ECR | ✅ | ✅ | future case studies |
| EC2 / VPC core | ⚠️ basic only | ✅ full (136 actions) | `modules/vpc-base` |
| NAT GW / VPC Endpoints / NACL / Flow Logs / Peering | ❌ | ✅ | `modules/vpc-base`, `vpc-peering` |
| Transit Gateway | ❌ | ❌ | gated (`enable_transit_gateway = false`) |
| VPC Endpoint Service (PrivateLink) | ❌ | ❌ | gated (`enable_privatelink = false`) |
| ELBv2 (ALB / NLB) | ✅ | ✅ | `modules/privatelink`, `modules/waf-v2` |
| WAF v2 | ❌ | ✅ | `modules/waf-v2` |
| Route53 | ✅ | ✅ | future case studies |
| CloudFront | ❌ | ✅ | future case studies |
| RDS / ElastiCache / MSK / OpenSearch / Athena | ✅ (real engines) | ❌ | future case studies |

---

## floci `:4566`

Floci is wire-compatible with LocalStack Community: `/_localstack/health` is served, and every AWS SDK / CLI call works unchanged when `endpoint_url = http://localhost:4566`.

### Identity (IAM, STS)

| Service | Coverage |
|---|---|
| IAM users / groups / roles / policies / permission boundaries / instance profiles / login profiles | ✅ |
| AWS-managed policies (seeded catalog) | ✅ |
| **Policy enforcement** | ✅ opt-in via `FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true` (bypass rules apply; see floci IAM docs) |
| STS — `GetCallerIdentity`, `AssumeRole`, `AssumeRoleWithWebIdentity`, `GetSessionToken`, all 7 ops | ✅ |

### Data plane

| Service | Coverage |
|---|---|
| S3 — buckets, versioning, encryption, public access block, lifecycle, replication, **Object Lock**, notifications, policy | ✅ |
| KMS — keys, aliases, encrypt/decrypt, sign/verify, rotation, policy | ✅ (real crypto) |
| SNS — topics, subscriptions, publish, policies | ✅ (cross-account policies stored, not enforced) |
| SQS — queues, DLQ, attributes, batches | ✅ (cross-account policies stored, not enforced) |
| Secrets Manager | ✅ |
| DynamoDB + DynamoDB Streams | ✅ |
| EventBridge / Scheduler / AppConfig | ✅ |
| Route53 hosted zones + health checks | ✅ |

### Compute

| Service | Coverage |
|---|---|
| EKS — `CreateCluster` / `DescribeCluster` / `ListClusters` / `DeleteCluster` / Tag* | ✅ real k3s container per cluster (mock via `FLOCI_SERVICES_EKS_MOCK=true`) |
| EKS access entries (`aws_eks_access_entry`, `aws_eks_access_policy_association`) | ❌ — keep `enable_eks_access_entries = false` |
| Lambda — all runtimes via public.ecr.aws/lambda/* | ✅ |
| ECS / ECR / CodeBuild / CodeDeploy / Auto Scaling | ✅ |
| EC2 — `RunInstances` (real Docker containers), instances, VPC, subnets, SGs, IGW, RT, EIP | ✅ basic |
| EC2 — NAT GW, NACL, Flow Logs, VPC Endpoints, Peering, Egress-only IGW, Launch Templates, Snapshots | ❌ — use ministack |

### Edge

| Service | Coverage |
|---|---|
| ELBv2 (ALB / NLB) | ✅ |
| API Gateway v1 + v2 | ✅ |
| CloudFront | ❌ |
| WAF v2 | ❌ |

### Database / streaming

| Service | Coverage |
|---|---|
| RDS (PostgreSQL / MySQL / MariaDB) | ✅ real engine + IAM auth |
| ElastiCache (Redis / Valkey) | ✅ real engine + IAM auth |
| MSK (Kafka via Redpanda) | ✅ |
| Kinesis + Firehose | ✅ |
| OpenSearch | ✅ |
| Athena (DuckDB sidecar) + Glue Data Catalog | ✅ |

### Floci environment variables

| Variable | Default | Purpose |
|---|---|---|
| `FLOCI_HOSTNAME` | (unset) | Hostname embedded in service URLs (set to `floci` for compose) |
| `FLOCI_BASE_URL` | (unset) | Full base URL alternative to `FLOCI_HOSTNAME` |
| `FLOCI_STORAGE_MODE` | `memory` | `memory` / `persistent` / `hybrid` / `wal` |
| `FLOCI_SERVICES_EKS_MOCK` | `false` | Skip k3s, return ACTIVE immediately |
| `FLOCI_SERVICES_EKS_DOCKER_NETWORK` | (unset) | Network for k3s containers |
| `FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED` | `false` | Activate the policy evaluator |
| `LOCALSTACK_PARITY` | `true` | Translate LocalStack env vars |
| `QUARKUS_LOG_LEVEL` | `INFO` | Log level |

---

## ministack `:4567`

MiniStack handles the enterprise networking primitives floci lacks. Detail below; this section is the inherited matrix from the previous (single-emulator) setup, re-rooted at port `:4567`.

### EC2 — VPC & Subnets

| Operation | ministack |
|---|---|
| CreateVpc / DescribeVpcs / DeleteVpc | ✅ |
| ModifyVpcAttribute / DescribeVpcAttribute (DNS support/hostnames) | ✅ |
| CreateSubnet / DeleteSubnet / DescribeSubnets / ModifySubnetAttribute | ✅ |
| CreateVpcEndpoint / DeleteVpcEndpoints / DescribeVpcEndpoints / ModifyVpcEndpoint | ✅ S3 Gateway + KMS/STS Interface |
| CreateVpcPeeringConnection / AcceptVpcPeeringConnection / Delete | ✅ |

### EC2 — Internet Gateway, NAT & Routing

| Operation | ministack |
|---|---|
| CreateInternetGateway / Attach/Detach / Delete / Describe | ✅ |
| CreateRouteTable / Delete / Describe / Associate / Disassociate / ReplaceAssociation | ✅ |
| CreateRoute / ReplaceRoute / DeleteRoute | ✅ |
| CreateNatGateway / DescribeNatGateways / DeleteNatGateway | ✅ |
| CreateEgressOnlyInternetGateway / Delete / Describe | ✅ |

### EC2 — Security Groups

| Operation | ministack |
|---|---|
| CreateSecurityGroup / DescribeSecurityGroups / DeleteSecurityGroup | ✅ (default SG always present) |
| Authorize / Revoke {Ingress, Egress} | ✅ (stored, not enforced) |
| DescribeSecurityGroupRules | ✅ |

### EC2 — Elastic IPs, ENIs, KeyPairs

| Operation | ministack |
|---|---|
| AllocateAddress / ReleaseAddress / Associate / Disassociate / DescribeAddresses / **DescribeAddressesAttribute** | ✅ |
| CreateNetworkInterface / Delete / Describe / Attach / Detach | ✅ |
| CreateKeyPair / DeleteKeyPair / DescribeKeyPairs / ImportKeyPair | ✅ |

### EC2 — NACL & Flow Logs

| Operation | ministack |
|---|---|
| CreateNetworkAcl / Describe / Delete + Entries + ReplaceAssociation | ✅ |
| CreateFlowLogs / Describe / Delete | ✅ |

### EC2 — DHCP, Launch Templates, Prefix Lists, VPN

| Operation | ministack |
|---|---|
| CreateDhcpOptions / Associate / Describe / Delete | ✅ |
| CreateLaunchTemplate(Version) / Describe / Modify / Delete | ✅ |
| DescribePrefixLists / Managed prefix lists CRUD + Entries | ✅ |
| CreateVpnGateway / Customer Gateway / Attach / Vgw route propagation | ✅ |

### EBS

| Operation | ministack |
|---|---|
| Volumes / Snapshots / Attach / Detach / Modify | ✅ |

### Transit Gateway — ❌ NOT IMPLEMENTED

| Operation | ministack |
|---|---|
| CreateTransitGateway / Describe / TGW VPC Attachment / TGW Peering Attachment | ❌ |

**Workaround:** keep `enable_transit_gateway = false` in `environments/prod/terraform.tfvars` (default). `modules/transit-gateway` still creates the surrounding VPCs, subnets, RTs, NAT GWs, and SGs.

### VPC Endpoint Service (PrivateLink) — ❌ NOT IMPLEMENTED

| Operation | ministack |
|---|---|
| CreateVpcEndpointServiceConfiguration / Describe | ❌ |

**Workaround:** keep `enable_privatelink = false` in `environments/prod/terraform.tfvars` (default). `modules/privatelink` still builds the NLB + VPCs + subnets.

### ELBv2 / ALB

| Operation | ministack |
|---|---|
| LoadBalancer / Listener / Rule / TargetGroup / RegisterTargets / Health / Tags | ✅ |

### WAF v2

| Operation | ministack |
|---|---|
| WebACL CRUD (`LockToken` required) | ✅ |
| AssociateWebACL / DisassociateWebACL / GetWebACLForResource / ListResourcesForWebACL | ✅ |
| IPSet / RuleGroup / TagResource / DescribeManagedRuleGroup | ✅ |

### Other ministack services usable but **not routed by this lab**

The following are supported by ministack but not pointed to from `endpoints {}` (floci serves them):

- S3, IAM, STS, KMS, SNS, SQS, Lambda, CloudFront, Route53, Cognito, AppSync.

If a future case study needs CloudFront, point `cloudfront → http://localhost:4567` since floci does not implement it.

### ministack environment variables

| Variable | Default | Purpose |
|---|---|---|
| `GATEWAY_PORT` | `4566` (mapped → host `4567`) | Container port |
| `LOG_LEVEL` | `INFO` | Log level |
| `PERSIST_STATE` | `0` | Persist state on shutdown |
| `S3_PERSIST` | `0` | Persist S3 separately |

---

## Module ↔ emulator matrix

| Module | Endpoints exercised | Resulting emulator |
|---|---|---|
| `modules/vpc-base` | ec2 (VPC/Subnet/IGW/NAT/RT/SG/EIP/Endpoint) | ministack `:4567` |
| `modules/vpc-peering` | ec2 (Peering, RT) | ministack `:4567` |
| `modules/privatelink` | ec2 + elbv2 + (optional) VPC Endpoint Service | ministack `:4567` (toggle off for service) |
| `modules/transit-gateway` | ec2 (VPC + RT + NAT) + (optional) TGW | ministack `:4567` (toggle off for TGW) |
| `modules/waf-v2` | wafv2 | ministack `:4567` |
| `iam/alb-controller` | iam + sts + ec2 + elbv2 | ministack `:4567` |
| `iam/cluster-access` | iam + sts + eks | ministack `:4567` (`enable_eks_access_entries=false` default) |
| `iam/cross-account` | iam + s3 + sts | ministack `:4567` |
| `iam/cross-account-secrets` | iam + sts + secretsmanager | ministack `:4567` |
| `iam/cross-region-pipeline` | iam + sns + sqs + sts | ministack `:4567` |
| `iam/cross-region-s3` | iam + s3 + sts | ministack `:4567` |
| `iam/external-dns-cross-account` | iam + route53 + sts | ministack `:4567` |
| `iam/prod` | iam + sns + sqs + sts | ministack `:4567` |
| `iam/s3-eks` | iam + s3 + sts | ministack `:4567` |
| `iam/s3-events` | iam + s3 + sns + sqs + sts | ministack `:4567` |
| `iam/s3-go-compute-matrix` | iam + s3 + sts | ministack `:4567` |
| `iam/stg` | iam + sns + sqs + sts | ministack `:4567` |
| `iam/storage-drivers` | iam + sts + ec2 | ministack `:4567` |

---

## Probing the emulators

```bash
# floci
curl -s http://localhost:4566/_localstack/health | jq

# ministack — also covered by:
./scripts/validate-ministack-apis.sh
```

`validate-ministack-apis.sh` honours `MINISTACK_ENDPOINT` (default `http://localhost:4567`).

---

## Terraform AWS provider compatibility

- This lab uses `hashicorp/aws >= 6.0`.
- ministack: fully compatible with v5 and v6 (all required APIs including `DescribeVpcClassicLink`, `DescribeAddressesAttribute`, `DescribeVpcAttribute`, `DescribeSecurityGroupRules` are implemented).
- floci: LocalStack-Community-compatible wire protocol on port `4566`; v6 works.

Commit every `.terraform.lock.hcl` so CI resolves the same provider build.
