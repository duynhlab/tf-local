#!/usr/bin/env bash
# Bring up the hybrid emulator stack:
#   floci      → :4566 (compute / IAM / data plane)
#   ministack  → :4567 (advanced networking + WAF)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Detect compose command (podman-compose > podman compose > docker compose)
if command -v podman-compose > /dev/null 2>&1; then
  DC="podman-compose"
elif podman compose version > /dev/null 2>&1; then
  DC="podman compose"
elif docker compose version > /dev/null 2>&1; then
  DC="docker compose"
else
  echo "ERROR: No compose command found (podman-compose, podman compose, docker compose)." >&2
  exit 1
fi

echo "=== Local AWS Lab – Setup ==="
echo "Using compose command: $DC"

cd "$PROJECT_DIR"

echo "[1/3] Starting emulators (floci + ministack)..."
$DC up -d floci ministack

wait_ready() {
  local name=$1 url=$2 max=${3:-40}
  echo "[*] Waiting for $name ($url) ..."
  for i in $(seq 1 "$max"); do
    if curl -sf "$url" > /dev/null 2>&1; then
      echo "    $name is ready"
      return 0
    fi
    sleep 3
  done
  echo "ERROR: $name did not become ready after $((max*3))s" >&2
  return 1
}

echo "[2/3] Waiting for readiness..."
wait_ready "floci"      "http://localhost:4566/_localstack/health"
wait_ready "ministack"  "http://localhost:4567/_ministack/health"

echo "[3/3] Health snapshot:"
echo "--- floci (:4566) ---"
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool 2>/dev/null || true
echo "--- ministack (:4567) ---"
curl -s http://localhost:4567/_ministack/health | python3 -m json.tool 2>/dev/null || true
