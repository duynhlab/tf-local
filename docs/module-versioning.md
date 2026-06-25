# Module versioning

## In-repo modules (`modules/`)

| Module | Path | Consumers |
|--------|------|-----------|
| VPC (3-tier) | `modules/networking/vpc` | `envs/*`, `envs/*`, `examples/` |
| WAF v2 | `modules/waf-v2` | Lab and AWS networking roots |
| IAM helpers | `modules/iam/*` | `iam/stg`, `iam/s3-eks`, … |
| Lab provider | `modules/lab-provider` | Symlinked as `lab_provider_common.tf` |

**Versioning:** monorepo **source paths** only (no registry pins). Breaking changes require updating all callers in the same PR.

Relative source depth:

| Root | Levels to repo root |
|------|---------------------|
| `envs/dev/networking` | `../../../../modules/...` |
| `envs/dev/ap-southeast-1/networking` | `../../../../../modules/...` |

## Provider lock files

Commit `.terraform.lock.hcl` for:

- `envs/*/networking/`
- `envs/*/ap-southeast-1/networking/`
- `bootstrap/`
- `iam/*/` (lab)

Regenerate after provider bumps:

```bash
terraform -chdir=envs/dev/ap-southeast-1/networking init -backend=false -upgrade
```

## Future external modules

If publishing to a private registry:

1. Tag repo releases (`modules/networking/vpc/v1.0.0` or Git tags).
2. Pin with `version = "~> 1.0"` and `source` registry address.
3. Keep lab on path sources until emulator CI is updated to pull modules.

## Deprecations

- `modules/vpc-base/` — README points to `modules/networking/vpc/`.
- `environments/*` — deprecated; use `envs/*`.
