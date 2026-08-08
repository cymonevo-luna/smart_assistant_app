#!/usr/bin/env bash
# Stop the shared Luna emulator started by start-shared-emulator.sh.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

resolve_android_sdk || true

stopped=0

if [ -f "$LUNA_EMULATOR_PID_FILE" ]; then
  pid="$(tr -d '\r\n' <"$LUNA_EMULATOR_PID_FILE")"
  if [ -n "$pid" ] && [ "$pid" != "0" ] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    stopped=1
    _flutter_test_env_log "Stopped emulator pid $pid"
  fi
fi

serial="$(read_shared_emulator_serial || true)"
if [ -n "$serial" ]; then
  "$(adb_bin)" -s "$serial" emu kill >/dev/null 2>&1 || true
  stopped=1
  _flutter_test_env_log "Sent emu kill to $serial"
fi

rm -f "$LUNA_EMULATOR_PID_FILE" "$LUNA_EMULATOR_DEVICE_FILE"

if [ "$stopped" -eq 0 ]; then
  _flutter_test_env_log "No shared emulator was running."
fi
