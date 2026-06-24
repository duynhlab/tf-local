#!/usr/bin/env bash
# floci-only smoke test:
#   - fmt + init(-backend=false) + validate for every live/envs networking root
#   - full apply/destroy for dev networking (proves it really works on floci)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TOTAL_PASS=0
TOTAL_FAIL=0

echo "=============================================="
echo "  tf-local – floci smoke test"
echo "=============================================="

"$SCRIPT_DIR/setup.sh"
echo ""

echo "[*] fmt check"
terraform -chdir="$PROJECT_DIR" fmt -check -recursive || { echo "fmt failed"; exit 1; }

validate_root() {
  local root="$1"
  echo "----------------------------------------------"
  echo "validate $root"
  echo "----------------------------------------------"
  if terraform -chdir="$PROJECT_DIR/$root" init -backend=false -input=false >/dev/null &&
     terraform -chdir="$PROJECT_DIR/$root" validate; then
    ((TOTAL_PASS++))
  else
    ((TOTAL_FAIL++)); echo "FAIL: $root"
  fi
}

for env in dev uat prod; do
  validate_root "live/envs/$env/ap-southeast-1/networking"
done

echo "----------------------------------------------"
echo "apply/destroy dev networking on floci"
echo "----------------------------------------------"
DEV="$PROJECT_DIR/live/envs/dev/ap-southeast-1/networking"
if terraform -chdir="$DEV" init -input=false &&
   terraform -chdir="$DEV" apply -auto-approve &&
   terraform -chdir="$DEV" output; then
  ((TOTAL_PASS++))
else
  ((TOTAL_FAIL++)); echo "FAIL: dev apply"
fi
terraform -chdir="$DEV" destroy -auto-approve || true

"$SCRIPT_DIR/teardown.sh"

echo "=============================================="
echo "  Summary: $TOTAL_PASS passed, $TOTAL_FAIL failed"
echo "=============================================="
[ "$TOTAL_FAIL" -gt 0 ] && exit 1 || exit 0
