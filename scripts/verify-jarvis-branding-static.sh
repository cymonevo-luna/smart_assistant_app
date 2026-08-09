#!/usr/bin/env bash
# Static verification for Jarvis platform launcher icons and favicons (QA JARVIS-35-2).
#
# Validates source icon assets on Android, web, iOS, macOS, and Windows plus
# packaged APK badging without a connected device.
#
# Usage (from repo root):
#   scripts/verify-jarvis-branding-static.sh
#   APK_PATH=build/app/outputs/flutter-apk/app-debug.apk scripts/verify-jarvis-branding-static.sh
#
# Env:
#   APK_PATH   apk to inspect (default: build/app/outputs/flutter-apk/app-debug.apk)
#
# Prerequisites:
#   - ffmpeg (or ImageMagick convert/magick, or python3+Pillow) for PNG color sampling
#   - Android SDK build-tools (aapt or aapt2) for APK badging
#   - debug APK at APK_PATH, or scripts/build-apk.sh available to build one
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/flutter-test-env.sh
source "$SCRIPT_DIR/lib/flutter-test-env.sh"

: "${APK_PATH:=$REPO_DIR/build/app/outputs/flutter-apk/app-debug.apk}"

ANDROID_DENSITIES=(mdpi hdpi xhdpi xxhdpi xxxhdpi)
WEB_ICONS=(
  "$REPO_DIR/web/favicon.png"
  "$REPO_DIR/web/icons/Icon-192.png"
  "$REPO_DIR/web/icons/Icon-512.png"
  "$REPO_DIR/web/icons/Icon-maskable-192.png"
  "$REPO_DIR/web/icons/Icon-maskable-512.png"
)
IOS_APPICONSET="$REPO_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
MACOS_APPICONSET="$REPO_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset"
WINDOWS_ICO="$REPO_DIR/windows/runner/resources/app_icon.ico"
WINDOWS_ICO_MIN_BYTES=100000

log() { printf '>> %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

usage() {
  cat <<EOF
Usage: scripts/verify-jarvis-branding-static.sh [--help]

Static Jarvis branding checks:
  - Android mipmap ic_launcher.png (all densities): exist, PNG, red-dominant RGB
  - APK badging: application-icon references mipmap ic_launcher
  - Web favicon and PWA icons: exist, PNG, red-dominant
  - iOS/macOS AppIcon.appiconset: every Contents.json PNG exists and non-empty
  - Windows app_icon.ico: exists and > ${WINDOWS_ICO_MIN_BYTES} bytes

Color pass criteria: average RGB has R > G and R > B (Jarvis red-dominant; not Flutter blue).

Environment:
  APK_PATH   apk to inspect (default: build/app/outputs/flutter-apk/app-debug.apk)

Examples:
  scripts/verify-jarvis-branding-static.sh
  APK_PATH=build/app/outputs/flutter-apk/app-debug.apk scripts/verify-jarvis-branding-static.sh
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

assert_non_empty_file() {
  local path="$1"
  local label="$2"
  [ -f "$path" ] || die "$label missing: $path"
  [ -s "$path" ] || die "$label empty: $path"
}

assert_png_file() {
  local path="$1"
  local label="$2"
  assert_non_empty_file "$path" "$label"
  local sig
  sig="$(head -c 8 "$path" | od -An -t x1 | tr -d ' \n')"
  [ "$sig" = "89504e470d0a1a0a" ] || die "$label is not a PNG (bad signature): $path"
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

  # Flutter default launcher is blue-dominant (B > R).
  if [ "$b" -gt "$r" ]; then
    die "$label looks like default Flutter blue (avg RGB=$r,$g,$b): $path"
  fi

  log "$label Jarvis coloring OK (avg RGB=$r,$g,$b): $path"
}

assert_android_mipmaps() {
  local density path
  for density in "${ANDROID_DENSITIES[@]}"; do
    path="$REPO_DIR/android/app/src/main/res/mipmap-${density}/ic_launcher.png"
    assert_png_file "$path" "Android mipmap-${density} ic_launcher"
    assert_jarvis_red_dominant "$path" "Android mipmap-${density} ic_launcher"
  done
  log "Android mipmap launcher icons: all densities branded"
}

assert_web_icons() {
  local path
  for path in "${WEB_ICONS[@]}"; do
    assert_png_file "$path" "Web icon"
    assert_jarvis_red_dominant "$path" "Web icon"
  done
  log "Web favicon and PWA icons: branded"
}

assert_appiconset() {
  local set_dir="$1"
  local platform="$2"
  local contents="$set_dir/Contents.json"
  [ -f "$contents" ] || die "$platform AppIcon Contents.json missing: $contents"

  python3 - "$contents" "$set_dir" <<'PY' || die "$platform AppIcon.appiconset validation failed"
import json, os, sys
contents_path, base = sys.argv[1], sys.argv[2]
with open(contents_path, encoding="utf-8") as fh:
    data = json.load(fh)
missing = []
empty = []
for entry in data.get("images", []):
    filename = entry.get("filename")
    if not filename:
        continue
    path = os.path.join(base, filename)
    if not os.path.isfile(path):
        missing.append(filename)
    elif os.path.getsize(path) == 0:
        empty.append(filename)
if missing:
    print("missing:", ", ".join(missing))
    sys.exit(1)
if empty:
    print("empty:", ", ".join(empty))
    sys.exit(1)
PY

  log "$platform AppIcon.appiconset: all referenced PNGs present"
}

assert_windows_ico() {
  assert_non_empty_file "$WINDOWS_ICO" "Windows app_icon.ico"
  local size
  size="$(wc -c <"$WINDOWS_ICO" | tr -d ' ')"
  if [ "$size" -le "$WINDOWS_ICO_MIN_BYTES" ]; then
    die "Windows app_icon.ico too small (${size} bytes; need > ${WINDOWS_ICO_MIN_BYTES})"
  fi
  log "Windows app_icon.ico present (${size} bytes)"
}

assert_apk_launcher_icon() {
  local aapt="$1"
  local badging icon_lines
  badging="$("$aapt" dump badging "$APK_PATH" 2>/dev/null || true)"
  [ -n "$badging" ] || die "Failed to dump APK badging from $APK_PATH"

  icon_lines="$(printf '%s\n' "$badging" | grep -E 'application-icon|^[[:space:]]*application:' || true)"
  if ! printf '%s\n' "$icon_lines" | grep -qi 'ic_launcher'; then
    die "APK badging missing ic_launcher application icon reference"
  fi
  if ! printf '%s\n' "$icon_lines" | grep -qi 'mipmap'; then
    die "APK badging application icon does not reference mipmap"
  fi

  log "APK badging launcher icon references ic_launcher mipmap"
  printf '%s\n' "$icon_lines" | grep -i 'ic_launcher' | head -n1 | while read -r line; do
    log "APK badging: $line"
  done
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

  assert_android_mipmaps
  assert_web_icons
  assert_appiconset "$IOS_APPICONSET" "iOS"
  assert_appiconset "$MACOS_APPICONSET" "macOS"
  assert_windows_ico
  ensure_apk
  assert_apk_launcher_icon "$aapt"

  log "Jarvis branding static verification PASSED"
}

main "$@"
