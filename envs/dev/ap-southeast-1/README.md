# dev / ap-southeast-1 — ECS Fargate environment

Real, copyable dev environment (Singapore). Two stacks with **separate S3 state +
S3-native locking** (Terraform ≥ 1.11, no DynamoDB):

```
networking/   VPC (10.100.0.0/16) + public/app/database subnets (3 AZ) + NAT + 3 SGs
ecs/          ECR + ALB + ECS Fargate service (reads networking via remote_state)
```

Design follows the Harley "Spring on ECS Fargate" flow: public ALB → private ECS
tasks → database tier, with a strict SG chain `internet → ALB → ECS → DB`.
CIDRs come from [`docs/subnet.csv`](../../../docs/subnet.csv).

## Apply order (real AWS)

```bash
# 0) One-time: create the state bucket (versioning + encryption + block-public)
./scripts/bootstrap-state-bucket.sh dnl-tfstate-<account-id> ap-southeast-1

# 1) networking
cd envs/dev/ap-southeast-1/networking
cp backend.hcl.example backend.hcl   # edit bucket name
terraform init -backend-config=backend.hcl
terraform apply

# 2) ecs (set state_bucket to the same bucket)
cd ../ecs
cp backend.hcl.example backend.hcl   # edit bucket name
terraform init -backend-config=backend.hcl
terraform apply -var state_bucket=dnl-tfstate-<account-id>
```

Provider config is **pure real AWS** (region + default_tags, credentials from your
normal AWS profile / role). Nothing emulator-specific is committed.

## Local testing on floci (optional)

The same code runs against floci using **environment variables only** — no code
changes. State backend uses `backend.floci.hcl`.

```bash
./scripts/setup.sh   # floci up
export AWS_ENDPOINT_URL=http://localhost:4566 AWS_ACCESS_KEY_ID=111111111111 \
       AWS_SECRET_ACCESS_KEY=test AWS_REGION=ap-southeast-1 AWS_S3_ADDRESSING_STYLE=path

./scripts/bootstrap-state-bucket.sh dnl-tfstate-floci ap-southeast-1

cd envs/dev/ap-southeast-1/networking
terraform init -reconfigure -backend-config=backend.floci.hcl
terraform apply -var enable_s3_gateway_endpoint=false        # floci gap, see below

cd ../ecs
terraform init -reconfigure -backend-config=backend.floci.hcl
terraform apply -var state_bucket=dnl-tfstate-floci \
  -var 'remote_state_config={access_key="111111111111",secret_key="test",use_path_style=true,skip_credentials_validation=true,skip_requesting_account_id=true,skip_metadata_api_check=true,endpoints={s3="http://localhost:4566"}}'
```

Verified e2e on floci 1.5.27: both stacks apply, cross-stack remote_state works,
and **S3 native locking is enforced**.

## floci gaps to set on this env (real AWS unaffected)

- `enable_s3_gateway_endpoint = false` — floci's `CreateVpcEndpoint` response isn't
  parseable by the AWS provider. Leave the default `true` on real AWS.
- AWS-managed IAM policies aren't preloaded → the ECS execution role uses an inline
  equivalent (real AWS can also attach the managed policy).
- Don't re-apply over a half-failed floci run (`ReplaceRoute` unsupported) — restart
  floci for a clean slate.

Full list + status: [`docs/floci-unsupported.md`](../../../docs/floci-unsupported.md).

## Notes
- ALB listener is HTTP-only for the lab; add an HTTPS listener + ACM cert + HTTP→HTTPS
  redirect for production.
- `container_image` defaults to a public nginx placeholder — replace with your app
  image (push to the ECR repo this stack creates), listening on `app_port` (8080).
- RDS is not provisioned here (the database subnets + DB SG are ready for it).
