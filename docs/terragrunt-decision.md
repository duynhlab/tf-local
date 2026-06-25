# Terragrunt decision

**Decision: do not adopt Terragrunt for this repository (2026).**

## Context

Track B adds `envs/<env>/<region>/<component>/` roots with S3 backends and optional `assume_role`. A wrapper could DRY backend and provider config.

## Options considered

| Approach | Pros | Cons |
|----------|------|------|
| **Plain Terraform roots** (chosen) | Simple, matches lab layout, no extra binary, easy `terraform validate` in CI | Some duplication of `backend.tf` / provider blocks |
| **Terragrunt** | Shared `root.hcl`, generated backends | Extra tool version pin, symlink/path complexity with monorepo modules, harder for contributors running lab-only |

## Rationale

1. Only **two** AWS networking roots exist today; duplication is small.
2. Lab track (`envs/`) must stay **zero-dependency** for emulator workflows.
3. CI already matrix-validates each root; Terragrunt would add `terragrunt hcl fmt` and cache paths.
4. If roots grow past ~10, revisit with a single `envs/root.hcl` **without** changing lab paths.

## Revisit when

- More than three regions or ten envs stacks
- Organization mandates central backend generation
- Team standardizes on Terragrunt elsewhere

Until then, copy `backend.hcl.example` and `terraform.tfvars.example` per stack.
