#!/usr/bin/env bash
# Create an S3 bucket for Terraform state with S3-native locking (no DynamoDB).
# Versioning + encryption + public access block, per best practice.
#
# Real AWS:   ./scripts/bootstrap-state-bucket.sh dnl-tfstate-<account-id> ap-southeast-1
# floci:      AWS_ENDPOINT_URL=http://localhost:4566 AWS_ACCESS_KEY_ID=111111111111 \
#             AWS_SECRET_ACCESS_KEY=test AWS_S3_ADDRESSING_STYLE=path \
#             ./scripts/bootstrap-state-bucket.sh dnl-tfstate-floci ap-southeast-1
set -euo pipefail

BUCKET="${1:?usage: bootstrap-state-bucket.sh <bucket-name> [region]}"
REGION="${2:-ap-southeast-1}"
EP=(); [ -n "${AWS_ENDPOINT_URL:-}" ] && EP=(--endpoint-url "$AWS_ENDPOINT_URL")

echo "[*] Creating bucket $BUCKET in $REGION ..."
if [ "$REGION" = "us-east-1" ]; then
  aws "${EP[@]}" s3api create-bucket --bucket "$BUCKET" --region "$REGION" 2>/dev/null || true
else
  aws "${EP[@]}" s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration "LocationConstraint=$REGION" 2>/dev/null || true
fi

echo "[*] Enabling versioning ..."
aws "${EP[@]}" s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo "[*] Enabling default encryption (AES256) ..."
aws "${EP[@]}" s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "[*] Blocking public access ..."
aws "${EP[@]}" s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "State bucket ready: $BUCKET ($REGION). Locking is S3-native (use_lockfile) — no DynamoDB."
