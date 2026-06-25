# Connectivity patterns — Peering vs PrivateLink vs Transit Gateway

Design rationale for the **prod networking** root
(`envs/prod/ap-southeast-1/networking`), which composes the cross-region/service
connectivity modules. On floci these are **`validate`/`plan`-only** (see
[floci-unsupported.md](floci-unsupported.md)); they apply on real AWS.

Modules: `networking/vpc-peering`, `networking/privatelink`,
`networking/transit-gateway` (+ `networking/vpc` main VPC, `security/wafv2` edge).

## When to use which

```mermaid
flowchart TD
  q1{"How many VPCs<br/>need to talk?"}
  q1 -->|"2 (full mesh ok)"| peer["VPC Peering"]
  q1 -->|"many / hub-spoke"| q2{"Cross-region or<br/>central routing?"}
  q2 -->|yes| tgw["Transit Gateway"]
  q2 -->|"just expose 1 service"| pl["PrivateLink (NLB + endpoint service)"]
  q1 -->|"expose a service,<br/>not the whole VPC"| pl
```

## Comparison

| | VPC Peering | PrivateLink | Transit Gateway |
|---|---|---|---|
| Connects | 2 VPCs (1:1) | a single **service** (one-way) | many VPCs (hub-spoke) |
| Routing | full route-table mesh | no routes — DNS to endpoint | central, scalable |
| Transitive | ❌ no | n/a | ✅ yes |
| Cross-region | ✅ | ✅ (inter-region endpoints) | ✅ (TGW peering) |
| Scale | poor (n² peerings) | great for service exposure | great for many VPCs |
| Cost shape | data transfer only | per-endpoint-hour + data | per-attachment-hour + data |
| Best for | a couple of VPCs | expose an app to consumers | org-wide mesh |

## Topologies

**Peering (cross-region, 1:1):**
```mermaid
flowchart LR
  a["VPC A · ap-southeast-1"] <-->|peering connection| b["VPC B · us-east-1"]
```

**PrivateLink (service exposure, one-way):**
```mermaid
flowchart LR
  subgraph prov["provider VPC"]
    nlb[NLB] --> svc["endpoint service"]
  end
  subgraph cons["consumer VPC"]
    ep["interface endpoint"]
  end
  ep -->|private DNS| svc
```

**Transit Gateway (hub-spoke, optionally cross-region):**
```mermaid
flowchart TB
  tgwA(("TGW · region A"))
  s1["spoke 1"] --- tgwA
  s2["spoke 2"] --- tgwA
  tgwA <-->|TGW peering| tgwB(("TGW · region B"))
  s3["spoke DR"] --- tgwB
```

## Edge security (WAF v2)

`security/wafv2` attaches a Web ACL (AWS managed rule groups + optional rate-based
+ IP sets) to the ALB. `scope = REGIONAL` for ALB/APIGW; `CLOUDFRONT` requires
`us-east-1`.

## Notes

- Peering / TGW / PrivateLink are **not supported on floci** — keep their toggles
  off (`enable_transit_gateway`, `enable_privatelink`) and treat the modules as
  `validate`/`plan`-only learning material until floci adds support.
- For service-to-service inside one region, also consider **VPC Lattice**
  (application-layer, identity-aware) — out of scope here; noted for completeness.
