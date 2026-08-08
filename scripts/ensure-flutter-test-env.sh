#!/usr/bin/env bash
# Verify the host Flutter/Android test environment without installing anything.
#
# Usage:
#   scripts/ensure-flutter-test-env.sh            # human-readable report
#   eval "$(scripts/ensure-flutter-test-env.sh --export)"  # shell exports
#   scripts/ensure-flutter-test-env.sh --check-vm # exit 0 when VM tests can run
#   scripts/ensure-flutter-test-env.sh --check-device # exit 0 when emulator ready
#
# Agents MUST run this before Flutter tests. Do NOT install Flutter, the Android
# SDK, system images, or new AVDs when this script reports missing tooling.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

MODE="${1:---report}"
FAIL=0

require_flutter() {
  if resolve_flutter_bin; then
    _flutter_test_env_log "Flutter: $($FLUTTER_BIN --version 2>/dev/null | head -n1)"
    return 0
  fi
  _flutter_test_env_log "ERROR: Flutter not found. Install Flutter on the host; do not bootstrap inside agent runs."
  FAIL=1
  return 1
}

require_android_sdk() {
  if resolve_android_sdk; then
    _flutter_test_env_log "Android SDK: $ANDROID_HOME"
    return 0
  fi
  _flutter_test_env_log "ERROR: Android SDK not found at $ANDROID_HOME. Configure the host SDK; do not download inside agent runs."
  FAIL=1
  return 1
}

report_emulators() {
  local serials
  serials="$(list_running_emulator_serials | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  if [ -n "$serials" ]; then
    _flutter_test_env_log "Running emulators: $serials"
    return 0
  fi
  _flutter_test_env_log "No running Android emulators."
  return 1
}

print_exports() {
  cat <<EOF
export ANDROID_HOME='$ANDROID_HOME'
export ANDROID_SDK_ROOT='$ANDROID_SDK_ROOT'
export PATH='$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:'"\$PATH"
export FLUTTER_BIN='$FLUTTER_BIN'
export SHARED_AVD='$SHARED_AVD'
EOF
}

case "$MODE" in
  --export)
    resolve_flutter_bin || true
    resolve_android_sdk || true
    print_exports
    exit 0
    ;;
  --check-vm)
    require_flutter
    exit "$FAIL"
    ;;
  --check-device)
    require_flutter
    require_android_sdk
    report_emulators || FAIL=1
    exit "$FAIL"
    ;;
  --report|*)
    _flutter_test_env_log "Luna Flutter test environment check"
    require_flutter || true
    require_android_sdk || true
    kvm_status_message || true
    _flutter_test_env_log "Shared AVD: $SHARED_AVD (${SHARED_EMULATOR_CORES} vCPU, ${SHARED_EMULATOR_MEMORY_MB} MB RAM)"
    report_emulators || true
    if [ "$FAIL" -eq 0 ]; then
      _flutter_test_env_log "VM tests: ready (flutter test test/integration/)"
      if report_emulators >/dev/null 2>&1; then
        _flutter_test_env_log "Device tests: emulator already running"
      else
        _flutter_test_env_log "Device tests: run scripts/start-shared-emulator.sh first"
      fi
    fi
    print_exports
    exit "$FAIL"
    ;;
esac
