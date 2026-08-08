#!/usr/bin/env bash
# Verify scheduled time-reminder local notification delivery (QA E2E).
#
# Schedules a test notification via the debug deep link (no staging API or
# assistant credentials required), backgrounds the app, and polls dumpsys until
# the reminder notification appears.
#
# Usage (from repo root):
#   scripts/verify-time-reminder-notification.sh
#   DEVICE=emulator-5554 scripts/verify-time-reminder-notification.sh
#   DELAY_SECONDS=5 scripts/verify-time-reminder-notification.sh
#
# Env:
#   DEVICE          adb serial (default: first device in `device` state)
#   APK_PATH        apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
#   PACKAGE         application id (default: com.cymonevo.smart_assistant)
#   TEST_MESSAGE    notification body (default: E2E reminder notification)
#   DELAY_SECONDS   seconds until notification fires (default: 5)
#
# Prerequisites:
#   - adb device/emulator in `device` state (see scripts/ensure-flutter-test-env.sh
#     and scripts/start-shared-emulator.sh)
#   - debuggable build (debug deep link is kDebugMode-only)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

: "${PACKAGE:=com.cymonevo.smart_assistant}"
: "${APK_PATH:=$REPO_DIR/build/app/outputs/flutter-apk/app-debug.apk}"
: "${TEST_MESSAGE:=E2E reminder notification}"
: "${DELAY_SECONDS:=5}"

NOTIFICATION_CHANNEL_ID="reminders"
NOTIFICATION_TITLE="Reminder"
POLL_INTERVAL_SEC=2
POLL_TIMEOUT_SEC=60

log() { printf '>> %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

usage() {
  cat <<EOF
Usage: scripts/verify-time-reminder-notification.sh [--help]

Verify a scheduled time-reminder local notification appears after the debug deep link
schedules it (no staging API credentials required).

Environment:
  DEVICE          adb serial (default: first connected device in device state)
  APK_PATH        apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
  PACKAGE         application id (default: com.cymonevo.smart_assistant)
  TEST_MESSAGE    notification body (default: E2E reminder notification)
  DELAY_SECONDS   seconds until notification fires (default: 5)

Examples:
  scripts/verify-time-reminder-notification.sh
  DEVICE=emulator-5554 DELAY_SECONDS=8 scripts/verify-time-reminder-notification.sh
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
    die "No adb device in 'device' state. Run scripts/ensure-flutter-test-env.sh and scripts/start-shared-emulator.sh first."
  fi

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
}

launch_app() {
  log "Launching $PACKAGE"
  adb_exec shell am start -n "$PACKAGE/.MainActivity" \
    -a android.intent.action.MAIN \
    -c android.intent.category.LAUNCHER >/dev/null
}

schedule_test_reminder() {
  local encoded_message
  encoded_message="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$TEST_MESSAGE")"
  local deep_link="smartassistant://debug/reminder-test?message=${encoded_message}&delay_seconds=${DELAY_SECONDS}"

  log "Scheduling test reminder via deep link (delay=${DELAY_SECONDS}s): $deep_link"
  adb_exec shell am start -a android.intent.action.VIEW \
    -d "$deep_link" \
    -n "$PACKAGE/.MainActivity" >/dev/null
}

background_app() {
  log "Sending app to background"
  adb_exec shell input keyevent KEYCODE_HOME
}

notification_dumpsys() {
  adb_exec shell dumpsys notification --list 2>/dev/null \
    || adb_exec shell dumpsys notification 2>/dev/null \
    || true
}

notification_present() {
  local dump="$1"
  printf '%s\n' "$dump" | grep -q "$PACKAGE" \
    && printf '%s\n' "$dump" | grep -Eqi "$NOTIFICATION_CHANNEL_ID|${NOTIFICATION_TITLE// /[[:space:]]}" \
    && printf '%s\n' "$dump" | grep -Fqi "$TEST_MESSAGE"
}

wait_for_notification() {
  local elapsed=0
  local dump
  while [ "$elapsed" -lt "$POLL_TIMEOUT_SEC" ]; do
    dump="$(notification_dumpsys)"
    if notification_present "$dump"; then
      log "Verified: reminder notification appeared with message '$TEST_MESSAGE'"
      return 0
    fi
    sleep "$POLL_INTERVAL_SEC"
    elapsed=$((elapsed + POLL_INTERVAL_SEC))
  done

  die "Timed out after ${POLL_TIMEOUT_SEC}s waiting for reminder notification (package=$PACKAGE channel=$NOTIFICATION_CHANNEL_ID title='$NOTIFICATION_TITLE' message='$TEST_MESSAGE')"
}

main() {
  case "${1:-}" in
    -h|--help|help)
      usage
      exit 0
      ;;
  esac

  resolve_device
  ensure_apk
  install_apk
  grant_runtime_permissions
  launch_app
  sleep 3
  schedule_test_reminder
  background_app
  wait_for_notification

  log "Time reminder notification E2E verification PASSED"
}

main "$@"
