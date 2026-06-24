# floci API Support

This lab runs **floci only** (`:4566`) + floci-ui (`:4500`). The earlier hybrid floci+ministack matrix is retired.

For the authoritative, probe-verified list of what floci supports vs. what it does **not** (with the re-check process), see:

➡️ **[floci-unsupported.md](floci-unsupported.md)**

Quick summary (floci 1.5.27, probed 2026-06-24):

- ✅ Apply works: VPC core (vpc/subnet/IGW/NAT/route/NACL), VPC Gateway endpoint (S3), ELBv2, WAFv2, IAM/STS, KMS, SSM SecureString, ECR, SNS/SQS, EKS, ECS, Lambda, multi-account isolation.
- ❌ Not supported (`UnsupportedOperation`): egress-only IGW (IPv6), VPC Flow Logs, VPC Peering, Transit Gateway. Modules for these are written for learning but stay `validate`/`plan`-only with toggles off.

Re-probe after a floci upgrade: `./scripts/probe-floci.sh` (add `PROBE_EKS=1` for EKS).
