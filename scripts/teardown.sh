#!/usr/bin/env bash
# Tear down the floci emulator stack.
# Set CONFIRM_DESTROY=1 to also run `terraform destroy` against every root first.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Detect compose command
if command -v podman-compose > /dev/null 2>&1; then
  DC="podman-compose"
elif podman compose version > /dev/null 2>&1; then
  DC="podman compose"
elif docker compose version > /dev/null 2>&1; then
  DC="docker compose"
else
  DC="podman compose"
fi

echo "=== Local AWS Lab – Teardown ==="

if [ "${CONFIRM_DESTROY:-0}" = "1" ]; then
  for root in envs/*/*/* shared-services/*/* examples/iam/*/; do
    if [ -d "$PROJECT_DIR/$root/.terraform" ]; then
      echo "[*] Destroying $root ..."
      (cd "$PROJECT_DIR/$root" && terraform destroy -auto-approve) || true
    fi
  done
else
  echo "[*] Skipping terraform destroy. Set CONFIRM_DESTROY=1 to enable cleanup."
fi

echo "[*] Stopping emulator containers..."
cd "$PROJECT_DIR"
$DC down -v || true

echo "Done."
