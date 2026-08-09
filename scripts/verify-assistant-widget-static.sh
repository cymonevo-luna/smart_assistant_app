#!/usr/bin/env bash
# Static verification for the 1×1 assistant home screen widget (QA JARVIS-20-2).
#
# Validates widget metadata, AndroidManifest entries, and packaged resources
# without a connected device.
#
# Usage (from repo root):
#   scripts/verify-assistant-widget-static.sh
#   APK_PATH=build/app/outputs/flutter-apk/app-debug.apk scripts/verify-assistant-widget-static.sh
#
# Env:
#   APK_PATH   apk to inspect (default: build/app/outputs/flutter-apk/app-debug.apk)
#
# Prerequisites:
#   - Android SDK build-tools (aapt or aapt2) for manifest/resource dumps
#   - debug APK at APK_PATH, or scripts/build-apk.sh available to build one
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

: "${APK_PATH:=$REPO_DIR/build/app/outputs/flutter-apk/app-debug.apk}"

WIDGET_INFO_SRC="$REPO_DIR/android/app/src/main/res/xml/assistant_widget_info.xml"
PACKAGE="com.cymonevo.smart_assistant"
APP_LABEL="Jarvis"

log() { printf '>> %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

usage() {
  cat <<EOF
Usage: scripts/verify-assistant-widget-static.sh [--help]

Static checks for the assistant 1×1 home screen widget:
  - widget_info 1×1 cell sizing and resizeMode=none
  - AndroidManifest deep links (widget-listen, plugin-setup/complete)
  - AssistantWidgetProvider exported with APPWIDGET_UPDATE
  - Widget layout/icon resources and app label in the APK

Environment:
  APK_PATH   apk to inspect (default: build/app/outputs/flutter-apk/app-debug.apk)

Examples:
  scripts/verify-assistant-widget-static.sh
  APK_PATH=build/app/outputs/flutter-apk/app-debug.apk scripts/verify-assistant-widget-static.sh
EOF
}

find_build_tools_dir() {
  local bt="$ANDROID_HOME/build-tools"
  [ -d "$bt" ] || return 1
  ls -1v "$bt" 2>/dev/null | tail -n1
}

resolve_aapt() {
  local version_dir tool
  version_dir="$(find_build_tools_dir)" || return 1
  for tool in "$ANDROID_HOME/build-tools/$version_dir/aapt2" \
              "$ANDROID_HOME/build-tools/$version_dir/aapt"; do
    if [ -x "$tool" ]; then
      printf '%s\n' "$tool"
      return 0
    fi
  done
  return 1
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

assert_widget_info_source() {
  [ -f "$WIDGET_INFO_SRC" ] || die "Missing source widget info: $WIDGET_INFO_SRC"

  grep -q 'android:targetCellWidth="1"' "$WIDGET_INFO_SRC" \
    || die "assistant_widget_info.xml missing targetCellWidth=1"
  grep -q 'android:targetCellHeight="1"' "$WIDGET_INFO_SRC" \
    || die "assistant_widget_info.xml missing targetCellHeight=1"
  grep -q 'android:resizeMode="none"' "$WIDGET_INFO_SRC" \
    || die "assistant_widget_info.xml missing resizeMode=none"

  log "Source widget_info: 1×1 cells, resizeMode=none"
}

dump_manifest() {
  local aapt="$1"
  if [[ "$aapt" == *aapt2 ]]; then
    "$aapt" dump xmltree --file AndroidManifest.xml "$APK_PATH" 2>/dev/null
  else
    "$aapt" dump xmltree "$APK_PATH" AndroidManifest.xml 2>/dev/null
  fi
}

manifest_contains() {
  local manifest="$1"
  local pattern="$2"
  grep -q "$pattern" <<<"$manifest"
}

assert_manifest() {
  local aapt="$1"
  local manifest
  manifest="$(dump_manifest "$aapt")"
  [ -n "$manifest" ] || die "Failed to dump AndroidManifest.xml from $APK_PATH"

  manifest_contains "$manifest" 'smartassistant' \
    || die "Manifest missing smartassistant scheme"
  manifest_contains "$manifest" 'assistant' \
    || die "Manifest missing assistant host"
  manifest_contains "$manifest" 'widget-listen' \
    || die "Manifest missing widget-listen path intent-filter"
  manifest_contains "$manifest" 'plugin-setup' \
    || die "Manifest missing plugin-setup host"
  manifest_contains "$manifest" '/complete' \
    || die "Manifest missing plugin-setup/complete path intent-filter"

  manifest_contains "$manifest" 'AssistantWidgetProvider' \
    || die "Manifest missing AssistantWidgetProvider receiver"
  manifest_contains "$manifest" 'APPWIDGET_UPDATE' \
    || die "Manifest missing APPWIDGET_UPDATE action"
  if ! manifest_contains "$manifest" 'AssistantWidgetProvider' \
    || ! printf '%s\n' "$manifest" | awk '
      /AssistantWidgetProvider/ { in_provider=1 }
      in_provider && /exported/ && /true|0xffffffff/ { found=1; exit }
      END { exit(found ? 0 : 1) }
    '; then
    die "Manifest missing exported=true on AssistantWidgetProvider"
  fi

  log "Manifest: widget-listen + plugin-setup/complete deep links, AssistantWidgetProvider exported"
}

apk_listing() {
  local aapt="$1"
  local listing=""
  if [[ "$aapt" == *aapt2 ]]; then
    listing="$("$aapt" dump resources "$APK_PATH" 2>/dev/null || true)"
  fi
  if [ -z "$listing" ]; then
    listing="$("$aapt" list "$APK_PATH" 2>/dev/null || true)"
  fi
  if [ -z "$listing" ]; then
    listing="$(unzip -l "$APK_PATH" 2>/dev/null || true)"
  fi
  printf '%s' "$listing"
}

assert_apk_resources() {
  local aapt="$1"
  local listing
  listing="$(apk_listing "$aapt")"
  [ -n "$listing" ] || die "Failed to list APK contents for $APK_PATH"

  grep -Eqi 'assistant_widget(\.|/|$)' <<<"$listing" \
    || die "APK missing assistant_widget resources"
  grep -Eqi 'assistant_widget_info' <<<"$listing" \
    || die "APK missing assistant_widget_info metadata"
  grep -Eqi 'ic_widget_mic' <<<"$listing" \
    || die "APK missing ic_widget_mic drawable"

  log "APK resources: widget layout/info/icon present"
}

assert_apk_label() {
  local aapt="$1"
  local badging label_line
  badging="$("$aapt" dump badging "$APK_PATH" 2>/dev/null || true)"

  if [ -n "$badging" ]; then
    label_line="$(printf '%s\n' "$badging" | grep "application-label:" | head -n1 || true)"
    if printf '%s' "$label_line" | grep -q "$APP_LABEL"; then
      log "APK application label: $APP_LABEL"
      return 0
    fi
    if printf '%s\n' "$badging" | grep -q "label='$APP_LABEL'"; then
      log "APK application label: $APP_LABEL"
      return 0
    fi
  fi

  # Fallback: strings.xml in APK or aapt strings dump
  if unzip -p "$APK_PATH" res/values/strings.xml 2>/dev/null | grep -q "$APP_LABEL"; then
    log "APK strings contain label: $APP_LABEL"
    return 0
  fi
  if [[ "$aapt" != *aapt2 ]] && "$aapt" dump --values resources "$APK_PATH" 2>/dev/null | grep -q "$APP_LABEL"; then
    log "APK resource values contain label: $APP_LABEL"
    return 0
  fi

  die "APK missing application label '$APP_LABEL'"
}

main() {
  case "${1:-}" in
    -h|--help|help)
      usage
      exit 0
      ;;
  esac

  resolve_android_sdk || die "Android SDK missing at ${ANDROID_HOME:-unset} (needed for aapt/aapt2)"
  local aapt
  aapt="$(resolve_aapt)" || die "aapt/aapt2 not found under $ANDROID_HOME/build-tools"

  assert_widget_info_source
  ensure_apk
  assert_manifest "$aapt"
  assert_apk_resources "$aapt"
  assert_apk_label "$aapt"

  log "Assistant widget static verification PASSED"
}

main "$@"
