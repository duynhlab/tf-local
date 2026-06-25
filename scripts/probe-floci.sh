#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Phase 0 capability probe for floci (:4566).
#
# Exercises the AWS actions that decide floci-only vs hybrid (see
# docs/floci-unsupported.md). Each check is isolated and
# non-fatal; a PASS/FAIL summary is printed at the end.
#
# Usage:
#   ./scripts/probe-floci.sh            # core probe (fast)
#   PROBE_EKS=1 ./scripts/probe-floci.sh # also probe EKS (spins real k3s, slow)
# ---------------------------------------------------------------------------
set -uo pipefail

ENDPOINT="${FLOCI_ENDPOINT:-http://localhost:4566}"
REGION="${AWS_REGION:-ap-southeast-1}"
export AWS_DEFAULT_REGION="$REGION"
export AWS_PAGER=""

# helper: aws against floci, optional account via 12-digit access key
awsf() { AWS_ACCESS_KEY_ID="${ACCT:-test}" AWS_SECRET_ACCESS_KEY=test aws --endpoint-url "$ENDPOINT" "$@"; }

PASS=(); FAIL=()
ok()   { PASS+=("$1"); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL+=("$1"); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
# run <label> <cmd...>  -> PASS if exit 0
run()  { local l="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$l"; else bad "$l"; fi; }

command -v aws >/dev/null || { echo "aws CLI not found"; exit 1; }
awsf sts get-caller-identity >/dev/null 2>&1 || { echo "floci not reachable at $ENDPOINT — start it first (./scripts/setup.sh)"; exit 1; }

echo "== GAP-2/3 Multi-account isolation =="
ACCT=111111111111 awsf sqs create-queue --queue-name probe-iso >/dev/null 2>&1
if ACCT=222222222222 awsf sqs get-queue-url --queue-name probe-iso >/dev/null 2>&1; then
  bad "multi-account isolation (queue visible cross-account!)"
else
  ok  "multi-account isolation (12-digit access key = separate account)"
fi
ACCT=111111111111 awsf sqs delete-queue --queue-url "$(ACCT=111111111111 awsf sqs get-queue-url --queue-name probe-iso --query QueueUrl --output text 2>/dev/null)" >/dev/null 2>&1

echo "== GAP-3 VPC core + advanced networking =="
VPC=$(awsf ec2 create-vpc --cidr-block 10.99.0.0/16 --query Vpc.VpcId --output text 2>/dev/null)
if [ -n "${VPC:-}" ] && [ "$VPC" != "None" ]; then
  ok "ec2 create-vpc ($VPC)"
  SUB=$(awsf ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.99.1.0/24 --query Subnet.SubnetId --output text 2>/dev/null)
  run "ec2 create-subnet" test -n "$SUB" -a "$SUB" != "None"
  IGW=$(awsf ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text 2>/dev/null)
  run "ec2 create-internet-gateway" test -n "$IGW" -a "$IGW" != "None"
  EIP=$(awsf ec2 allocate-address --domain vpc --query AllocationId --output text 2>/dev/null)
  if [ -n "${EIP:-}" ] && [ "$EIP" != "None" ] && [ -n "${SUB:-}" ]; then
    run "ec2 create-nat-gateway" awsf ec2 create-nat-gateway --subnet-id "$SUB" --allocation-id "$EIP"
  else bad "ec2 create-nat-gateway (prereq eip/subnet failed)"; fi
  run "ec2 create-route-table"       awsf ec2 create-route-table --vpc-id "$VPC"
  run "ec2 create-vpc-endpoint (gw S3)" awsf ec2 create-vpc-endpoint --vpc-id "$VPC" --service-name "com.amazonaws.$REGION.s3" --vpc-endpoint-type Gateway
  run "ec2 create-network-acl"        awsf ec2 create-network-acl --vpc-id "$VPC"
  run "ec2 create-egress-only-igw"    awsf ec2 create-egress-only-internet-gateway --vpc-id "$VPC"
  run "ec2 create-flow-logs (cwl)"    awsf ec2 create-flow-logs --resource-type VPC --resource-ids "$VPC" --traffic-type ALL --log-group-name probe-fl --deliver-logs-permission-arn "arn:aws:iam::000000000000:role/probe"
  VPC2=$(awsf ec2 create-vpc --cidr-block 10.98.0.0/16 --query Vpc.VpcId --output text 2>/dev/null)
  run "ec2 create-vpc-peering"        awsf ec2 create-vpc-peering-connection --vpc-id "$VPC" --peer-vpc-id "$VPC2"
  run "ec2 create-transit-gateway"    awsf ec2 create-transit-gateway
else bad "ec2 create-vpc (networking probe skipped)"; fi

echo "== GAP-4 ELBv2 =="
run "elbv2 create-target-group" awsf elbv2 create-target-group --name probe-tg --protocol HTTP --port 80 --vpc-id "${VPC:-vpc-x}" --target-type ip
# ALB needs >=2 subnets; light check only
run "elbv2 describe-load-balancers" awsf elbv2 describe-load-balancers

echo "== GAP-5 WAFv2 =="
run "wafv2 create-ip-set"  awsf wafv2 create-ip-set --name probe-ip --scope REGIONAL --ip-address-version IPV4 --addresses 10.0.0.0/24
run "wafv2 list-web-acls"  awsf wafv2 list-web-acls --scope REGIONAL

echo "== GAP-7 KMS / SSM / ECR =="
run "kms create-key"       awsf kms create-key
run "ssm put SecureString" awsf ssm put-parameter --name /probe/secret --type SecureString --value s3cr3t
run "ecr create-repository" awsf ecr create-repository --repository-name probe-repo

if [ "${PROBE_EKS:-0}" = "1" ]; then
  echo "== GAP-6 EKS / Pod Identity (slow) =="
  run "eks list-clusters"            awsf eks list-clusters
  run "eks describe-addon-versions"  awsf eks describe-addon-versions --addon-name eks-pod-identity-agent
fi

echo
echo "================= SUMMARY ================="
printf 'PASS: %d   FAIL: %d\n' "${#PASS[@]}" "${#FAIL[@]}"
if [ "${#FAIL[@]}" -gt 0 ]; then
  echo "Failed checks (floci-only: toggle-off the feature + document the gap):"
  printf '  - %s\n' "${FAIL[@]}"
fi
