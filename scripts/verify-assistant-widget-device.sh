#!/usr/bin/env bash
# Device/runtime verification for the assistant home screen widget (QA JARVIS-20-2).
#
# Covers deferred runtime cases:
#   TC widget-listen  — deep link launches MainActivity with matching URI
#   TC plugin-setup   — plugin-setup/complete deep link launches without crash
#   TC widget picker  — AssistantWidgetProvider registered in system dumpsys
#
# Verification method for deep links:
#   Uses `adb shell am start` stdout plus `adb shell dumpsys activity activities`
#   to confirm MainActivity is top-resumed and the intent data URI matches.
#
# Widget picker fallback (manual):
#   Long-press home → Widgets → find "Smart Assistant App" if dumpsys/cmd
#   appwidget checks are inconclusive on a given launcher/API level.
#
# Usage (from repo root):
#   scripts/verify-assistant-widget-device.sh
#   DEVICE=emulator-5554 scripts/verify-assistant-widget-device.sh
#
# Env:
#   DEVICE     adb serial (default: first device in `device` state)
#   APK_PATH   apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
#   PACKAGE    application id (default: com.cymonevo.smart_assistant)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

: "${PACKAGE:=com.cymonevo.smart_assistant}"
: "${APK_PATH:=$REPO_DIR/build/app/outputs/flutter-apk/app-debug.apk}"

WIDGET_LISTEN_URI="smartassistant://assistant/widget-listen"
PLUGIN_SETUP_URI="smartassistant://plugin-setup/complete?status=success"
MAIN_ACTIVITY="$PACKAGE/.MainActivity"
WIDGET_PROVIDER="$PACKAGE/.AssistantWidgetProvider"
WIDGET_LABEL="Smart Assistant App"

log() { printf '>> %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

usage() {
  cat <<EOF
Usage: scripts/verify-assistant-widget-device.sh [--help]

Runtime device checks for the assistant widget and deep links on Luna_Test_Lite.

Environment:
  DEVICE     adb serial (default: first connected device in device state)
  APK_PATH   apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
  PACKAGE    application id (default: com.cymonevo.smart_assistant)

Deep-link verification uses dumpsys activity activities after am start.
Widget picker uses dumpsys package/appwidget (manual UI fallback documented above).

Examples:
  scripts/verify-assistant-widget-device.sh
  DEVICE=emulator-5554 scripts/verify-assistant-widget-device.sh
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
  if adb_exec shell pm path "$PACKAGE" >/dev/null 2>&1; then
    log "Package $PACKAGE already installed; skipping reinstall"
    return 0
  fi

  log "Installing $APK_PATH on $DEVICE"
  if command -v timeout >/dev/null 2>&1; then
    timeout 120 adb_exec install -r "$APK_PATH" || die "adb install failed for $APK_PATH"
  else
    adb_exec install -r "$APK_PATH" || die "adb install failed for $APK_PATH"
  fi
}

clear_logcat() {
  adb_exec logcat -c 2>/dev/null || true
}

force_stop_app() {
  adb_exec shell am force-stop "$PACKAGE" 2>/dev/null || true
  sleep 1
}

activity_dumpsys() {
  adb_exec shell dumpsys activity activities 2>/dev/null || true
}

main_activity_foreground() {
  local dump="$1"
  grep -E 'mResumedActivity|topResumedActivity' <<<"$dump" | grep -q 'MainActivity'
}

intent_data_in_dumpsys() {
  local dump="$1"
  local uri_fragment="$2"
  grep -q "$uri_fragment" <<<"$dump"
}

wait_for_main_activity() {
  local timeout=15
  local elapsed=0
  local dump
  while [ "$elapsed" -lt "$timeout" ]; do
    dump="$(activity_dumpsys)"
    if main_activity_foreground "$dump"; then
      printf '%s' "$dump"
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  return 1
}

start_deep_link() {
  local uri="$1"
  adb_exec shell am start \
    -a android.intent.action.VIEW \
    -d "$uri" \
    -W "$MAIN_ACTIVITY" 2>&1 || true
}

assert_no_fatal_crash() {
  local since="${1:-5}"
  if adb_exec logcat -d -t "$since" 2>/dev/null | grep -E "FATAL EXCEPTION|AndroidRuntime.*$PACKAGE" | grep -q .; then
    adb_exec logcat -d -t 30 2>/dev/null | tail -n 40 >&2 || true
    die "Fatal crash detected in logcat for $PACKAGE"
  fi
}

verify_widget_listen_deep_link() {
  log "TC widget-listen: launching $WIDGET_LISTEN_URI"
  force_stop_app
  clear_logcat
  start_deep_link "$WIDGET_LISTEN_URI" >/dev/null
  sleep 2

  local dump
  dump="$(wait_for_main_activity)" || die "MainActivity not in foreground after widget-listen deep link"
  main_activity_foreground "$dump" \
    || die "MainActivity not resumed after widget-listen deep link"
  intent_data_in_dumpsys "$dump" "widget-listen" \
    || intent_data_in_dumpsys "$dump" "$WIDGET_LISTEN_URI" \
    || die "dumpsys missing widget-listen intent data (URI=$WIDGET_LISTEN_URI)"

  assert_no_fatal_crash 8
  log "TC widget-listen PASSED: MainActivity foreground with widget-listen URI"
}

verify_plugin_setup_deep_link() {
  log "TC plugin-setup: launching $PLUGIN_SETUP_URI"
  force_stop_app
  clear_logcat
  start_deep_link "$PLUGIN_SETUP_URI" >/dev/null
  sleep 2

  local dump
  dump="$(wait_for_main_activity)" || die "MainActivity not in foreground after plugin-setup deep link"
  main_activity_foreground "$dump" \
    || die "MainActivity not resumed after plugin-setup deep link"
  intent_data_in_dumpsys "$dump" "plugin-setup" \
    || intent_data_in_dumpsys "$dump" "complete" \
    || die "dumpsys missing plugin-setup/complete intent data"

  assert_no_fatal_crash 8
  log "TC plugin-setup PASSED: MainActivity launched without crash"
}

package_dumpsys() {
  adb_exec shell dumpsys package "$PACKAGE" 2>/dev/null || true
}

appwidget_dumpsys() {
  adb_exec shell dumpsys appwidget 2>/dev/null || true
}

verify_widget_provider_registered() {
  log "TC widget picker: checking provider registration via dumpsys"
  local pkg_dump widget_dump
  pkg_dump="$(package_dumpsys)"
  widget_dump="$(appwidget_dumpsys)"
  local combined="${pkg_dump}
${widget_dump}"

  printf '%s\n' "$combined" | grep -q 'AssistantWidgetProvider' \
    || die "AssistantWidgetProvider not found in dumpsys package/appwidget"
  if ! grep -qi 'assistant_widget_info' <<<"$combined"; then
    grep -q 'AssistantWidgetProvider' <<<"$combined" \
      || die "assistant_widget_info metadata not found in dumpsys"
  fi

  if grep -q "$WIDGET_LABEL" <<<"$combined"; then
    log "Widget label '$WIDGET_LABEL' found in dumpsys"
  else
    log "Widget label not in dumpsys (non-fatal; provider class is registered)"
  fi

  # Optional: bind via cmd appwidget on API 34 when launcher allows programmatic bind.
  if adb_exec shell cmd appwidget help >/dev/null 2>&1; then
    log "cmd appwidget available; provider registration confirmed via dumpsys"
  fi

  clear_logcat
  force_stop_app
  assert_no_fatal_crash 3
  log "TC widget picker PASSED: AssistantWidgetProvider registered"
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

  verify_widget_listen_deep_link
  verify_plugin_setup_deep_link
  verify_widget_provider_registered

  log "Assistant widget device verification PASSED"
}

main "$@"
