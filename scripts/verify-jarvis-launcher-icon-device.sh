#!/usr/bin/env bash
# Device verification for Jarvis Android launcher icon (QA JARVIS-35-2).
#
# Primary pass/fail: extract ic_launcher.png from the installed APK and verify
# red-dominant Jarvis coloring (not default Flutter blue). Home-screen screencap
# is supplementary only because launcher UI varies by OEM/API level.
#
# Usage (from repo root):
#   scripts/verify-jarvis-launcher-icon-device.sh
#   DEVICE=emulator-5554 scripts/verify-jarvis-launcher-icon-device.sh
#
# Env:
#   DEVICE     adb serial (default: running emulator or scripts/start-shared-emulator.sh)
#   APK_PATH   apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
#   PACKAGE    application id (default: com.cymonevo.smart_assistant)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

: "${PACKAGE:=com.cymonevo.smart_assistant}"
: "${APK_PATH:=$REPO_DIR/build/app/outputs/flutter-apk/app-debug.apk}"

MAIN_ACTIVITY="$PACKAGE/.MainActivity"
WORK_DIR="${TMPDIR:-/tmp}/jarvis-launcher-icon-$$"

log() { printf '>> %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

usage() {
  cat <<EOF
Usage: scripts/verify-jarvis-launcher-icon-device.sh [--help]

Runtime device checks for the Jarvis launcher icon on Luna_Test_Lite.

Verification method:
  1. Install debug APK and confirm LAUNCHER MainActivity registration.
  2. Pull installed base.apk and extract res/mipmap-*/ic_launcher.png.
  3. Sample average RGB (R > G, R > B) to confirm Jarvis branding.
  4. Optionally press HOME and capture launcher screencap (supplementary).

Environment:
  DEVICE     adb serial (default: running emulator or start-shared-emulator.sh)
  APK_PATH   apk to install (default: build/app/outputs/flutter-apk/app-debug.apk)
  PACKAGE    application id (default: com.cymonevo.smart_assistant)

Examples:
  scripts/verify-jarvis-launcher-icon-device.sh
  DEVICE="\$(scripts/start-shared-emulator.sh | tail -n1)" scripts/verify-jarvis-launcher-icon-device.sh
EOF
}

adb_exec() {
  "$(adb_bin)" ${DEVICE:+-s "$DEVICE"} "$@"
}

png_average_rgb() {
  local path="$1"
  local rgb=""

  if command -v convert >/dev/null 2>&1; then
    rgb="$(convert "$path" -scale 1x1\! -format '%[pixel:s]' info: 2>/dev/null \
      | sed -n 's/.*srgb(\([0-9]*\),\([0-9]*\),\([0-9]*\)).*/\1 \2 \3/p' \
      | head -n1)"
    if [ -n "$rgb" ]; then
      printf '%s' "$rgb"
      return 0
    fi
  fi

  if command -v magick >/dev/null 2>&1; then
    rgb="$(magick "$path" -scale 1x1\! -format '%[pixel:s]' info: 2>/dev/null \
      | sed -n 's/.*srgb(\([0-9]*\),\([0-9]*\),\([0-9]*\)).*/\1 \2 \3/p' \
      | head -n1)"
    if [ -n "$rgb" ]; then
      printf '%s' "$rgb"
      return 0
    fi
  fi

  if command -v ffmpeg >/dev/null 2>&1; then
    rgb="$(ffmpeg -hide_banner -loglevel error -i "$path" \
      -vf scale=1:1 -frames:v 1 -f rawvideo -pix_fmt rgb24 pipe:1 2>/dev/null \
      | od -An -t u1 | awk '{print $1, $2, $3}' | head -n1)"
    if [ -n "$rgb" ]; then
      printf '%s' "$rgb"
      return 0
    fi
  fi

  if command -v python3 >/dev/null 2>&1; then
    rgb="$(python3 - "$path" <<'PY' 2>/dev/null || true
import sys
try:
    from PIL import Image
except ImportError:
    sys.exit(2)
path = sys.argv[1]
im = Image.open(path).convert("RGB")
small = im.resize((1, 1))
r, g, b = small.getpixel((0, 0))
print(f"{r} {g} {b}")
PY
)"
    if [ -n "$rgb" ]; then
      printf '%s' "$rgb"
      return 0
    fi
  fi

  die "No image tool available to sample PNG colors (need ffmpeg, ImageMagick, or python3+Pillow)"
}

assert_jarvis_red_dominant() {
  local path="$1"
  local label="$2"
  local rgb r g b
  rgb="$(png_average_rgb "$path")"
  r="$(printf '%s' "$rgb" | awk '{print $1}')"
  g="$(printf '%s' "$rgb" | awk '{print $2}')"
  b="$(printf '%s' "$rgb" | awk '{print $3}')"

  if [ -z "$r" ] || [ -z "$g" ] || [ -z "$b" ]; then
    die "$label color sample failed for $path"
  fi

  if [ "$r" -le "$g" ] || [ "$r" -le "$b" ]; then
    die "$label not Jarvis red-dominant (avg RGB=$r,$g,$b; need R>G and R>B): $path"
  fi

  if [ "$b" -gt "$r" ]; then
    die "$label looks like default Flutter blue (avg RGB=$r,$g,$b): $path"
  fi

  log "$label Jarvis coloring OK (avg RGB=$r,$g,$b)"
}

resolve_device() {
  resolve_android_sdk || die "Android SDK missing at ${ANDROID_HOME:-unset}"

  if [ -n "${DEVICE:-}" ]; then
    wait_for_adb_device_online "$DEVICE" 420 || die "Device $DEVICE not online"
    return 0
  fi

  DEVICE="$(pick_running_emulator_serial || true)"
  if [ -z "$DEVICE" ]; then
    log "No running emulator; starting shared emulator (up to 7 minutes)..."
    DEVICE="$(bash "$SCRIPT_DIR/start-shared-emulator.sh" | tail -n1)"
  fi

  if [ -z "$DEVICE" ]; then
    die "No adb device in 'device' state. Run scripts/ensure-flutter-test-env.sh and scripts/start-shared-emulator.sh first."
  fi

  wait_for_adb_device_online "$DEVICE" 420 || die "Device $DEVICE not online"
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

assert_package_installed() {
  local path_line
  path_line="$(adb_exec shell pm path "$PACKAGE" 2>/dev/null | head -n1 | tr -d '\r')"
  [ -n "$path_line" ] || die "Package $PACKAGE not installed on $DEVICE"
  log "Package installed: $path_line"
}

assert_launcher_activity() {
  local resolve_out
  resolve_out="$(adb_exec shell cmd package resolve-activity \
    -a android.intent.action.MAIN \
    -c android.intent.category.LAUNCHER \
    "$PACKAGE" 2>/dev/null | tr -d '\r')"

  if ! printf '%s' "$resolve_out" | grep -q 'MainActivity'; then
    die "LAUNCHER resolve-activity missing MainActivity for $PACKAGE"
  fi
  log "LAUNCHER activity resolves to MainActivity"
}

extract_installed_launcher_icon() {
  local remote_apk local_apk listing icon_path density
  remote_apk="$(adb_exec shell pm path "$PACKAGE" 2>/dev/null | head -n1 | sed 's/^package://' | tr -d '\r')"
  [ -n "$remote_apk" ] || die "Could not resolve installed apk path for $PACKAGE"

  mkdir -p "$WORK_DIR"
  local_apk="$WORK_DIR/installed.apk"
  adb_exec pull "$remote_apk" "$local_apk" >/dev/null 2>&1 \
    || die "adb pull failed for $remote_apk"

  listing="$(unzip -l "$local_apk" 2>/dev/null || true)"
  icon_path="$(printf '%s\n' "$listing" | awk '/res\/mipmap-[^/]+-v[0-9]+\/ic_launcher\.png$/ { print $4; exit }')"
  if [ -z "$icon_path" ]; then
    icon_path="$(printf '%s\n' "$listing" | awk '/res\/mipmap[^/]*\/ic_launcher\.png$/ { print $4; exit }')"
  fi
  [ -n "$icon_path" ] || die "Installed APK missing res/mipmap ic_launcher.png entries"

  unzip -p "$local_apk" "$icon_path" >"$WORK_DIR/ic_launcher.png" \
    || die "Failed to extract $icon_path from installed APK"
  [ -s "$WORK_DIR/ic_launcher.png" ] || die "Extracted launcher icon is empty"

  density="$(basename "$(dirname "$icon_path")")"
  log "Extracted launcher icon from installed APK ($density)"
  printf '%s' "$WORK_DIR/ic_launcher.png"
}

verify_application_info_icon() {
  local dump
  dump="$(adb_exec shell dumpsys package "$PACKAGE" 2>/dev/null | tr -d '\r')"
  if printf '%s' "$dump" | grep -q 'applicationInfo'; then
    if printf '%s' "$dump" | grep -A2 'applicationInfo' | grep -qi 'ic_launcher'; then
      log "dumpsys package references ic_launcher in applicationInfo context"
      return 0
    fi
    log "dumpsys package applicationInfo present (icon resource confirmed via APK extraction)"
  fi
}

supplementary_home_screencap() {
  adb_exec shell input keyevent KEYCODE_HOME 2>/dev/null || true
  sleep 2
  if adb_exec exec-out screencap -p >"$WORK_DIR/home.png" 2>/dev/null; then
    if [ -s "$WORK_DIR/home.png" ]; then
      log "Supplementary home screencap saved ($WORK_DIR/home.png)"
    fi
  else
    log "Home screencap skipped (non-fatal)"
  fi
}

cleanup() {
  rm -rf "$WORK_DIR"
}

main() {
  case "${1:-}" in
    -h|--help|help)
      usage
      exit 0
      ;;
  esac

  trap cleanup EXIT

  resolve_device
  ensure_apk
  install_apk
  assert_package_installed
  assert_launcher_activity
  verify_application_info_icon

  local icon_path
  icon_path="$(extract_installed_launcher_icon)"
  assert_jarvis_red_dominant "$icon_path" "Installed APK launcher icon"
  supplementary_home_screencap

  log "Jarvis launcher icon device verification PASSED"
}

main "$@"
