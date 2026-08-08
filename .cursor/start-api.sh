#!/usr/bin/env bash
# Start smart_assistant_api for agent runs (sibling repo checkout layout).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=resolve-api-dir.sh
source "$SCRIPT_DIR/resolve-api-dir.sh"

API_DIR="$(ensure_api_repo)"

if [ -x "$API_DIR/scripts/qa-local-up.sh" ]; then
  exec "$API_DIR/scripts/qa-local-up.sh"
fi

cd "$API_DIR"

for _ in $(seq 1 30); do
  if docker info >/dev/null 2>&1; then
    exec docker compose up --build
  fi
  if sudo docker info >/dev/null 2>&1; then
    exec sudo docker compose up --build
  fi
  sleep 2
done

echo "ERROR: Docker daemon is not running. Start Docker and retry." >&2
exit 1
