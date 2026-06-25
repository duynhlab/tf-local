# lab-provider

Shared **locals** for floci emulator Terraform roots (not a provider module — Terraform cannot configure providers from module outputs).

## Usage

Symlink into each root module (relative target depends on depth):

```bash
# envs/<env>/<region>/<component>  (5 levels deep)
ln -sf ../../../../../modules/lab-provider/common.tf lab_provider_common.tf
# examples/iam/<scenario>  (3 levels deep)
ln -sf ../../../modules/lab-provider/common.tf lab_provider_common.tf
```

Then in `providers.tf`:

- `local.lab_accounts.<env>` → 12-digit account id for the provider `access_key` (floci isolates resources per account).
- `local.lab_secret_key_test` → `"test"`.
- An endpoint map for the `endpoints {}` block — all maps now point to floci `:4566`. Map names are kept stable (`lab_hybrid_endpoints`, `lab_ministack_endpoints_*`) for backward compatibility; pick the one whose service keys match the root.

See [AGENTS.md](../../AGENTS.md) and [docs/floci-unsupported.md](../../docs/floci-unsupported.md).
