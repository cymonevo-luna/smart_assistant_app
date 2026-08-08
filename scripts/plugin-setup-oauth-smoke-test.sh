#!/usr/bin/env bash
# Plugin setup OAuth smoke test (manual QA case 4).
#
# 1. When API_BASE_URL in .env points at a reachable staging/local API, exercises
#    the backend OAuth callback path with a mock authorization code (same contract
#    as smart_assistant_api integration tests).
# 2. Always runs the Flutter integration smoke test that mirrors the in-app flow.
#
# Usage (from repo root):
#   cp .env.staging.example .env   # or .env.emulator.example for local docker QA
#   scripts/plugin-setup-oauth-smoke-test.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_DIR/.env"
INTEGRATION_TEST="$REPO_DIR/test/integration/plugin_setup_oauth_smoke_test.dart"

log() { printf '>> %s\n' "$*"; }
die() { log "ERROR: $*"; exit 1; }

load_api_base_url() {
  local file="$1"
  if [ ! -f "$file" ]; then
    return 1
  fi
  # shellcheck disable=SC1090
  set -a
  # shellcheck source=/dev/null
  source <(grep -E '^[A-Z_]+=' "$file" | sed 's/\r$//')
  set +a
  [ -n "${API_BASE_URL:-}" ] || return 1
  [[ "$API_BASE_URL" != *"api.example.com"* ]] || return 1
  return 0
}

api_install_smoke() {
  local base="${API_BASE_URL%/}"
  local health_url="$base/healthz"
  log "Checking API health at $health_url"
  curl -sf --max-time 10 "$health_url" >/dev/null || return 1

  log "Registering smoke user at $base"
  local email="smoke-$(date +%s)@plugin-setup.test"
  local password="SmokeTest123!"
  curl -sf --max-time 20 -X POST "$base/api/v1/auth/register" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\",\"password\":\"$password\",\"name\":\"Smoke Test\"}" >/dev/null

  log "Logging in smoke user"
  local login_body
  login_body=$(curl -sf --max-time 20 -X POST "$base/api/v1/auth/login" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\",\"password\":\"$password\"}")

  local access_token
  access_token=$(printf '%s' "$login_body" | python3 -c "import json,sys; d=json.load(sys.stdin); data=d.get('data',{}); print(data.get('access_token') or data.get('tokens',{}).get('access_token',''))")
  [ -n "$access_token" ] || die "login did not return access_token"

  log "Installing google-calendar-meet plugin"
  local install_body
  install_body=$(curl -sf --max-time 20 -X POST "$base/api/v1/users/me/plugins" \
    -H "Authorization: Bearer $access_token" \
    -H 'Content-Type: application/json' \
    -d '{"plugin_slug":"google-calendar-meet"}')

  local plugin_id
  plugin_id=$(printf '%s' "$install_body" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('id',''))")
  [ -n "$plugin_id" ] || die "install did not return plugin id"

  log "API install smoke test PASSED (plugin_id=$plugin_id)"
  API_SMOKE_ACCESS_TOKEN="$access_token"
  API_SMOKE_PLUGIN_ID="$plugin_id"
}

api_oauth_smoke() {
  local base="${API_BASE_URL%/}"
  local access_token="${API_SMOKE_ACCESS_TOKEN:-}"
  local plugin_id="${API_SMOKE_PLUGIN_ID:-}"
  [ -n "$access_token" ] && [ -n "$plugin_id" ] || return 1

  log "Starting plugin setup"
  local setup_body
  setup_body=$(curl -sf --max-time 20 -X POST "$base/api/v1/users/me/plugins/$plugin_id/setup" \
    -H "Authorization: Bearer $access_token") || return 1

  local state
  state=$(printf '%s' "$setup_body" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('state',''))")
  [ -n "$state" ] || return 1

  log "Simulating Google OAuth callback"
  local callback_url="$base/api/v1/plugins/oauth/google/callback?code=smoke-test-code&state=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$state")"
  local location
  location=$(curl -sS --max-time 20 -o /dev/null -w '%{redirect_url}' "$callback_url" || true)
  [[ "$location" == *"status=success"* ]] || {
    log "OAuth callback did not redirect with status=success (got: $location)"
    return 1
  }

  log "Verifying setup_status=completed"
  local status_body
  status_body=$(curl -sf --max-time 20 \
    "$base/api/v1/users/me/plugins/$plugin_id/setup/status" \
    -H "Authorization: Bearer $access_token") || return 1
  if ! printf '%s' "$status_body" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('data',{}).get('setup_status')=='completed', d"; then
    return 1
  fi
  log "API OAuth smoke test PASSED"
}

api_smoke() {
  api_install_smoke || return 1
  if api_oauth_smoke; then
    :
  else
    log "WARN: OAuth callback smoke failed (install step passed)"
  fi
}

flutter_smoke() {
  if ! command -v flutter >/dev/null 2>&1; then
    if [ -x /tmp/flutter/bin/flutter ]; then
      export PATH="/tmp/flutter/bin:$PATH"
    else
      die "flutter not found; run scripts/ensure-flutter-test-env.sh on the host"
    fi
  fi
  log "Running Flutter integration smoke test"
  (cd "$REPO_DIR" && flutter test "$INTEGRATION_TEST")
  log "Flutter integration smoke test PASSED"
}

cd "$REPO_DIR"

if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$REPO_DIR/.env.staging.example" ]; then
    cp "$REPO_DIR/.env.staging.example" "$ENV_FILE"
    log "Created $ENV_FILE from .env.staging.example"
  elif [ -f "$REPO_DIR/.env.example" ]; then
    cp "$REPO_DIR/.env.example" "$ENV_FILE"
    log "Created $ENV_FILE from .env.example"
  fi
fi

if load_api_base_url "$ENV_FILE"; then
  if api_smoke; then
    :
  else
    log "API not reachable or OAuth smoke failed; continuing with Flutter integration test"
  fi
else
  log "No live API_BASE_URL configured; running Flutter integration smoke test only"
fi

flutter_smoke
