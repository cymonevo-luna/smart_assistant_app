#!/usr/bin/env bash
# Ensure /dev/kvm is usable, then start or reuse Luna_Test_Lite.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../scripts/lib/flutter-test-env.sh
source "$SCRIPT_DIR/../scripts/lib/flutter-test-env.sh"

if [ -e /dev/kvm ] && ! [ -w /dev/kvm ]; then
  if getent group kvm >/dev/null; then
    sudo chgrp kvm /dev/kvm 2>/dev/null || true
    sudo chmod g+rw /dev/kvm 2>/dev/null || true
  fi
fi

if serial="$("$SCRIPT_DIR/../scripts/start-shared-emulator.sh" 2>/dev/null | grep -E '^emulator-[0-9]+$' || true)"; then
  echo "$serial"
  exit 0
fi

resolve_android_sdk || {
  _flutter_test_env_log "ERROR: Android SDK missing at $ANDROID_HOME"
  exit 1
}

gpu_flag="-gpu swiftshader_indirect"
if kvm_usable || kvm_group_member; then
  gpu_flag="-gpu auto"
fi

_flutter_test_env_log "KVM acceleration unavailable or unreliable; starting Luna_Test_Lite with software CPU (-no-accel, slow)."

run_with_kvm "$(
  emulator_bin
)" \
  -avd "$SHARED_AVD" \
  -cores "$SHARED_EMULATOR_CORES" \
  -memory "$SHARED_EMULATOR_MEMORY_MB" \
  -no-audio \
  -no-window \
  -no-boot-anim \
  -no-metrics \
  -no-accel \
  $gpu_flag \
  -no-snapshot-save \
  >/dev/null 2>&1 &

serial=""
for _ in $(seq 1 90); do
  serial="$(pick_running_emulator_serial || true)"
  [ -n "$serial" ] && break
  sleep 2
done

if [ -z "$serial" ]; then
  _flutter_test_env_log "ERROR: Emulator started but no adb serial appeared."
  exit 1
fi

wait_for_emulator_boot "$serial" 600
echo "$serial"
