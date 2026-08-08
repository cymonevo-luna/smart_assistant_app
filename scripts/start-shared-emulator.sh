#!/usr/bin/env bash
# Start (or reuse) the single shared Android emulator for Flutter device tests.
#
# Usage:
#   scripts/start-shared-emulator.sh
#
# Policy: reuse any running emulator — never start a second one.
# AVD: Luna_Test_Lite only (1536 MB RAM, 1 vCPU, Nexus 5X, API 34).
#
# Manual smoke tests against a local API on the host: copy .env.emulator.example
# to .env so the app targets http://10.0.2.2:8080 from the emulator.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

if [ -n "${SHARED_AVD:-}" ] && [ "$SHARED_AVD" != "Luna_Test_Lite" ]; then
  printf '>> ERROR: Agent device tests must use Luna_Test_Lite (SHARED_AVD=%s).\n' "$SHARED_AVD" >&2
  exit 1
fi

# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

if [ "${SHARED_AVD:-}" != "Luna_Test_Lite" ]; then
  _flutter_test_env_log "ERROR: Agent device tests must use Luna_Test_Lite (got '${SHARED_AVD:-}')."
  exit 1
fi

resolve_android_sdk || {
  _flutter_test_env_log "ERROR: Android SDK missing at $ANDROID_HOME"
  exit 1
}

existing="$(pick_running_emulator_serial || true)"
if [ -n "$existing" ]; then
  if emulator_boot_completed "$existing"; then
    record_shared_emulator "$(pgrep -f "emulator.*-avd ${SHARED_AVD}" | head -n1 || echo 0)" "$existing"
    echo "$existing"
    _flutter_test_env_log "Reusing running emulator: $existing"
    exit 0
  fi
  _flutter_test_env_log "Found $existing but boot is incomplete; waiting..."
  wait_for_emulator_boot "$existing"
  record_shared_emulator "$(pgrep -f 'qemu-system' | head -n1 || echo 0)" "$existing"
  echo "$existing"
  exit 0
fi

if shared_emulator_pid_alive; then
  serial="$(read_shared_emulator_serial || true)"
  if [ -n "$serial" ] && emulator_boot_completed "$serial"; then
    echo "$serial"
    _flutter_test_env_log "Reusing tracked emulator: $serial"
    exit 0
  fi
fi

if ! "$(
  emulator_bin
)" -list-avds 2>/dev/null | grep -Fxq "$SHARED_AVD"; then
  _flutter_test_env_log "ERROR: Shared AVD '$SHARED_AVD' not found."
  _flutter_test_env_log "Available AVDs:"
  "$(
    emulator_bin
  )" -list-avds >&2 || true
  _flutter_test_env_log "Create Luna_Test_Lite on the host once; do not create AVDs inside agent runs."
  exit 1
fi

gpu_flag="-gpu auto"
if ! kvm_usable && ! kvm_group_member; then
  gpu_flag="-gpu swiftshader_indirect"
  _flutter_test_env_log "KVM unavailable; starting emulator with software rendering (slow)."
fi

_flutter_test_env_log "Starting shared emulator AVD=$SHARED_AVD (${SHARED_EMULATOR_CORES} core, ${SHARED_EMULATOR_MEMORY_MB} MB) ..."
run_with_kvm "$(
  emulator_bin
)" \
  -avd "$SHARED_AVD" \
  -cores "$SHARED_EMULATOR_CORES" \
  -memory "$SHARED_EMULATOR_MEMORY_MB" \
  -no-audio \
  -no-window \
  -no-boot-anim \
  -no-snapshot-save \
  $gpu_flag \
  >/dev/null 2>&1 &

emu_pid=$!
record_shared_emulator "$emu_pid" ""

serial=""
if ! serial="$(wait_for_emulator_serial 300)"; then
  _flutter_test_env_log "ERROR: Emulator process started (pid $emu_pid) but no adb serial became ready."
  exit 1
fi

record_shared_emulator "$emu_pid" "$serial"
echo "$serial"
_flutter_test_env_log "Shared emulator ready: $serial"
