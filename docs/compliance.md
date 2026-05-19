# Compliance and policy checks

## Tools

| Tool | Scope | CI job |
|------|-------|--------|
| **Checkov** | Terraform + custom rules in `policies/checkov/` | `aws-ci.yml` — **hard fail** (`soft_fail: false`) |
| **Trivy** | HIGH/CRITICAL misconfigurations | `ci.yml` (lab track) |
| **TFLint** | Style and provider lint | `ci.yml` |

Config: [`.checkov.yml`](../.checkov.yml) sets `external-checks-dir: policies/checkov`.

## Custom Checkov rules

Add Python checks under `policies/checkov/` following the pattern in `require_s3_public_access_block.py` (`CKV_TF_LOCAL_*` IDs).

Local run:

```bash
checkov -d . --config-file .checkov.yml
```

## Lab vs AWS

- **`live/lab/*`**: emulator endpoints; some AWS checks are skipped or N/A.
- **`live/aws/*`**, **`bootstrap/`**: must pass Checkov in AWS CI without suppressions unless documented in code with `# checkov:skip=CKV_...` and a one-line reason.

## Pre-push

```bash
terraform fmt -check -recursive
checkov -d . --config-file .checkov.yml
trivy config --severity HIGH,CRITICAL live/aws/ bootstrap/
```

Optional: [Conftest](https://www.conftest.dev/) can be added later for Rego policies on `terraform plan -json` output; not required for the current pipeline.
