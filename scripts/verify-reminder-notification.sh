#!/usr/bin/env bash
# Verify location-reminder local notification appears on Android emulator/device.
#
# Usage (from repo root):
#   scripts/verify-reminder-notification.sh
#   DEVICE=emulator-5554 scripts/verify-reminder-notification.sh
#
# Env:
#   DEVICE     adb serial (default: first device in `device` state)
#   APK_PATH   apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
#   PACKAGE    application id (default: com.cymonevo.smart_assistant)
#
# Prerequisites:
#   - adb device/emulator in `device` state
#   - Flutter SDK on PATH
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

: "${PACKAGE:=com.cymonevo.smart_assistant}"
: "${APK_PATH:=$REPO_DIR/build/app/outputs/flutter-apk/app-debug.apk}"

NOTIFICATION_CHANNEL_ID="location_reminders"
NOTIFICATION_TITLE="Location Reminder"
POLL_INTERVAL_SEC=2

log() { printf '>> %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

usage() {
  cat <<EOF
Usage: scripts/verify-reminder-notification.sh [--help]

Build/install the debug APK, run the reminder notification integration test
on the device, and verify the notification appears in dumpsys.

Environment:
  DEVICE     adb serial (default: first connected device in device state)
  APK_PATH   apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
  PACKAGE    application id (default: com.cymonevo.smart_assistant)
EOF
}

adb_exec() {
  "$(adb_bin)" ${DEVICE:+-s "$DEVICE"} "$@"
}

resolve_device() {
  resolve_android_sdk || die "Android SDK missing at ${ANDROID_HOME:-unset}"

  if [ -n "${DEVICE:-}" ]; then
    return 0
  fi

  DEVICE="$(pick_running_emulator_serial || true)"
  if [ -z "$DEVICE" ]; then
    DEVICE="$("$(adb_bin)" devices 2>/dev/null | awk '/^[[:space:]]*[^[:space:]]+[[:space:]]+device$/ { print $1; exit }')"
  fi

  if [ -z "$DEVICE" ]; then
    die "No adb device in 'device' state. Run scripts/start-shared-emulator.sh first."
  fi

  export DEVICE
}

ensure_emulator() {
  if [ -n "${DEVICE:-}" ] && [ "$(adb_device_state "$DEVICE")" = "device" ]; then
    return 0
  fi

  if [ -n "$(pick_running_emulator_serial || true)" ]; then
    return 0
  fi

  log "No online emulator; starting shared Luna_Test_Lite AVD..."
  DEVICE="$(bash "$SCRIPT_DIR/start-shared-emulator.sh" | tail -n1)"
  export DEVICE
}

ensure_apk() {
  if [ -f "$APK_PATH" ]; then
    log "Using APK: $APK_PATH"
    return 0
  fi

  log "APK not found at $APK_PATH; building debug apk..."
  local built=""
  built="$(bash "$SCRIPT_DIR/build-apk.sh" debug | tail -n1)"
  [ -f "$built" ] || die "build-apk.sh did not produce an apk at $built"
  APK_PATH="$built"
  log "Built APK: $APK_PATH"
}

install_apk() {
  log "Installing $APK_PATH on $DEVICE"
  adb_exec install -r "$APK_PATH" || die "adb install failed for $APK_PATH"
}

grant_runtime_permissions() {
  log "Granting POST_NOTIFICATIONS"
  adb_exec shell pm grant "$PACKAGE" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
  adb_exec shell appops set "$PACKAGE" POST_NOTIFICATION allow 2>/dev/null || true
}

notification_dumpsys() {
  adb_exec shell dumpsys notification 2>/dev/null || true
}

notification_present() {
  local dump="$1"
  printf '%s\n' "$dump" | grep -q "NotificationRecord.*${PACKAGE}" \
    && printf '%s\n' "$dump" | grep -Eqi "$NOTIFICATION_CHANNEL_ID|${NOTIFICATION_TITLE// /[[:space:]]}"
}

run_integration_test() {
  resolve_flutter_bin || die "Flutter not found"
  log "Running reminder notification integration test on $DEVICE"
  (
    cd "$REPO_DIR"
    "$FLUTTER_BIN" test integration_test/reminder_notification_test.dart -d "$DEVICE"
  )
}

main() {
  case "${1:-}" in
    -h|--help|help)
      usage
      exit 0
      ;;
  esac

  ensure_emulator
  resolve_device
  ensure_apk
  install_apk
  grant_runtime_permissions

  local verified_flag poll_pid test_rc
  verified_flag="$(mktemp)"

  (
    while true; do
      if notification_present "$(notification_dumpsys)"; then
        echo ok >"$verified_flag"
        exit 0
      fi
      sleep "$POLL_INTERVAL_SEC"
    done
  ) &
  poll_pid=$!

  run_integration_test
  test_rc=$?
  kill "$poll_pid" 2>/dev/null || true
  wait "$poll_pid" 2>/dev/null || true

  if [ "$test_rc" -ne 0 ]; then
    rm -f "$verified_flag"
    die "Integration test failed (exit=$test_rc)"
  fi

  if [ ! -f "$verified_flag" ]; then
    rm -f "$verified_flag"
    die "Reminder notification not visible during integration test"
  fi
  rm -f "$verified_flag"

  log "Reminder notification verification PASSED"
}

main "$@"
