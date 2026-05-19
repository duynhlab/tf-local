# lab-provider

Shared **locals** for local emulator Terraform roots (not a provider module — Terraform cannot configure providers from module outputs).

## Usage

Symlink into each root module:

```bash
ln -sf ../../modules/lab-provider/common.tf lab_provider_common.tf   # environments/*
ln -sf ../../modules/lab-provider/common.tf lab_provider_common.tf   # iam/*
```

Reference `local.lab_hybrid_endpoints` or `local.lab_ministack_endpoints_*` in `providers.tf`.

See [docs/support.md](../../docs/support.md) and [AGENTS.md](../../AGENTS.md).
