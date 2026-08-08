#!/usr/bin/env bash
# Verify active-listening foreground-service notification lifecycle (QA TC5/TC6).
#
# Automates host-side checks that the FGS notification is present while active
# listening is enabled and absent after it is disabled — without manual dumpsys
# interpretation each run.
#
# Usage (from repo root):
#   scripts/verify-active-listening-notification.sh
#   DEVICE=emulator-5554 scripts/verify-active-listening-notification.sh
#   APK_PATH=build/app/outputs/flutter-apk/app-debug.apk scripts/verify-active-listening-notification.sh
#
# Env:
#   DEVICE     adb serial (default: first device in `device` state)
#   APK_PATH   apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
#   PACKAGE    application id (default: com.cymonevo.smart_assistant)
#
# Prerequisites:
#   - adb device/emulator in `device` state (see scripts/ensure-flutter-test-env.sh
#     and scripts/start-shared-emulator.sh)
#   - debuggable build for `run-as` shared-preference writes
#
# Toggle strategy:
#   Writes [PreferencesService] keys via `adb shell run-as` (assistant_active_listening)
#   then restarts the app so [assistantSettingsProvider] / [ActiveListeningController]
#   apply cached settings without fragile UI taps. Falls back to documented settings
#   deep navigation + input tap only when run-as is unavailable.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

: "${PACKAGE:=com.cymonevo.smart_assistant}"
: "${APK_PATH:=$REPO_DIR/build/app/outputs/flutter-apk/app-debug.apk}"

NOTIFICATION_CHANNEL_ID="active_listening"
NOTIFICATION_TITLE="Active listening"
PREF_ACTIVE_LISTENING="assistant_active_listening"
PREF_WAKE_WORD="assistant_wake_word"
POLL_INTERVAL_SEC=2
POLL_TIMEOUT_SEC=30

log() { printf '>> %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

usage() {
  cat <<EOF
Usage: scripts/verify-active-listening-notification.sh [--help]

Verify the active-listening FGS notification appears while monitoring is on
and disappears after it is turned off (QA test cases 5 and 6).

Environment:
  DEVICE     adb serial (default: first connected device in device state)
  APK_PATH   apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
  PACKAGE    application id (default: com.cymonevo.smart_assistant)

Examples:
  scripts/verify-active-listening-notification.sh
  DEVICE=emulator-5554 scripts/verify-active-listening-notification.sh
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
  log "Granting POST_NOTIFICATIONS and RECORD_AUDIO"
  adb_exec shell pm grant "$PACKAGE" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
  adb_exec shell pm grant "$PACKAGE" android.permission.RECORD_AUDIO 2>/dev/null || true
}

launch_app() {
  log "Launching $PACKAGE"
  adb_exec shell am start -n "$PACKAGE/.MainActivity" \
    -a android.intent.action.MAIN \
    -c android.intent.category.LAUNCHER >/dev/null
}

restart_app() {
  log "Restarting $PACKAGE to apply settings"
  adb_exec shell am force-stop "$PACKAGE"
  sleep 1
  launch_app
}

bootstrap_app_data() {
  launch_app
  sleep 3
  adb_exec shell am force-stop "$PACKAGE"
}

run_as_available() {
  adb_exec shell run-as "$PACKAGE" true >/dev/null 2>&1
}

write_flutter_prefs() {
  local active_listening="$1"
  local wake_word="${2:-Jarvis}"
  local tmp
  tmp="$(mktemp)"

  cat >"$tmp" <<EOF
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <boolean name="flutter.${PREF_ACTIVE_LISTENING}" value="${active_listening}" />
    <string name="flutter.${PREF_WAKE_WORD}">${wake_word}</string>
</map>
EOF

  adb_exec push "$tmp" /sdcard/FlutterSharedPreferences.xml >/dev/null
  rm -f "$tmp"

  adb_exec shell run-as "$PACKAGE" mkdir -p shared_prefs
  adb_exec shell run-as "$PACKAGE" cp /sdcard/FlutterSharedPreferences.xml \
    shared_prefs/FlutterSharedPreferences.xml
  adb_exec shell rm -f /sdcard/FlutterSharedPreferences.xml
}

# Documented UI fallback when run-as is unavailable (e.g. non-debuggable build).
toggle_active_listening_via_ui() {
  local enable="$1"
  log "run-as unavailable; using settings UI fallback (fragile across locales/layouts)"
  log "Open settings: adb shell am start -n $PACKAGE/.MainActivity (then Profile -> Settings)"
  launch_app
  sleep 4
  adb_exec shell am start -n "$PACKAGE/.MainActivity" \
    -a android.intent.action.VIEW \
    -d "smartassistant://settings" >/dev/null 2>&1 || true
  sleep 2
  # Nexus 5X / API 34 emulator coordinates for the Active listening switch (logged).
  local tap_x=980
  local tap_y=1180
  log "Tapping active-listening switch at ${tap_x},${tap_y}"
  adb_exec shell input tap "$tap_x" "$tap_y"
  sleep 1
  if [ "$enable" = "false" ]; then
    log "Tapping again to disable active listening"
    adb_exec shell input tap "$tap_x" "$tap_y"
  fi
}

set_active_listening_enabled() {
  local enabled="$1"
  if run_as_available; then
    write_flutter_prefs "$enabled"
    restart_app
    return 0
  fi
  toggle_active_listening_via_ui "$enabled"
}

notification_dumpsys() {
  adb_exec shell dumpsys notification --list 2>/dev/null \
    || adb_exec shell dumpsys notification 2>/dev/null \
    || true
}

foreground_service_dumpsys() {
  adb_exec shell dumpsys activity services \
    com.pravera.flutter_foreground_task.service.ForegroundService 2>/dev/null \
    || true
}

notification_present() {
  local dump="$1"
  printf '%s\n' "$dump" | grep -q "$PACKAGE" \
    && printf '%s\n' "$dump" | grep -Eqi "$NOTIFICATION_CHANNEL_ID|${NOTIFICATION_TITLE// /[[:space:]]}"
}

foreground_service_running() {
  local dump="$1"
  printf '%s\n' "$dump" | grep -q "$PACKAGE" \
    && printf '%s\n' "$dump" | grep -qi "foregroundServiceType=microphone"
}

wait_for_notification() {
  local expect_present="$1"
  local label
  if [ "$expect_present" = "true" ]; then
    label="active-listening notification to appear"
  else
    label="active-listening notification to disappear"
  fi

  local elapsed=0
  local dump fgs_dump
  while [ "$elapsed" -lt "$POLL_TIMEOUT_SEC" ]; do
    dump="$(notification_dumpsys)"
    if [ "$expect_present" = "true" ]; then
      if notification_present "$dump"; then
        fgs_dump="$(foreground_service_dumpsys)"
        if foreground_service_running "$fgs_dump"; then
          log "Foreground service running with microphone type"
        else
          log "Notification present; foreground service microphone type not confirmed (non-fatal)"
        fi
        log "Verified: $label"
        return 0
      fi
    else
      if ! notification_present "$dump"; then
        log "Verified: $label"
        return 0
      fi
    fi
    sleep "$POLL_INTERVAL_SEC"
    elapsed=$((elapsed + POLL_INTERVAL_SEC))
  done

  if [ "$expect_present" = "true" ]; then
    die "Timed out after ${POLL_TIMEOUT_SEC}s waiting for $label (package=$PACKAGE channel=$NOTIFICATION_CHANNEL_ID title='$NOTIFICATION_TITLE')"
  fi
  die "Timed out after ${POLL_TIMEOUT_SEC}s waiting for $label"
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
  bootstrap_app_data

  log "Enabling active listening (TC5)"
  set_active_listening_enabled true
  wait_for_notification true

  log "Disabling active listening (TC6)"
  set_active_listening_enabled false
  wait_for_notification false

  log "Active listening notification lifecycle verification PASSED"
}

main "$@"
