#!/usr/bin/env bash
# Unit tests for scripts/verify-jarvis-launcher-icon-device.sh (no device required).
#
# Run: bash scripts/verify-jarvis-launcher-icon-device.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
VERIFY="$SCRIPT_DIR/verify-jarvis-launcher-icon-device.sh"
LIB="$SCRIPT_DIR/lib/flutter-test-env.sh"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

[ -f "$VERIFY" ] || { echo "FAIL: verify-jarvis-launcher-icon-device.sh missing"; exit 1; }
[ -f "$LIB" ] || { echo "FAIL: lib/flutter-test-env.sh missing"; exit 1; }
[ -x "$VERIFY" ] || chmod +x "$VERIFY"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fails=0
check() {
  if [ "$2" = "$3" ]; then
    echo "ok   - $1"
  else
    echo "FAIL - $1: got [$2], want [$3]"
    fails=$((fails + 1))
  fi
}

bash -n "$VERIFY"
echo "ok   - bash -n syntax check"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$VERIFY" "$SCRIPT_DIR/verify-jarvis-launcher-icon-device.test.sh"
  echo "ok   - shellcheck"
else
  echo "ok   - shellcheck skipped (not installed)"
fi

help_out="$(bash "$VERIFY" --help 2>&1)"
printf '%s' "$help_out" | grep -q "verify-jarvis-launcher-icon-device.sh" \
  || { echo "FAIL - --help missing script name"; fails=$((fails + 1)); }
printf '%s' "$help_out" | grep -q "DEVICE" \
  || { echo "FAIL - --help missing DEVICE"; fails=$((fails + 1)); }
printf '%s' "$help_out" | grep -q "APK_PATH" \
  || { echo "FAIL - --help missing APK_PATH"; fails=$((fails + 1)); }
if [ "$fails" -eq 0 ]; then
  echo "ok   - --help documents usage"
fi

mkdir -p "$WORK/fake-sdk/platform-tools" "$WORK/fake-sdk/emulator" \
  "$WORK/build/app/outputs/flutter-apk" "$WORK/scripts/lib" "$WORK/apk-staging/res/mipmap-xxxhdpi-v4"

cp "$VERIFY" "$WORK/scripts/verify-jarvis-launcher-icon-device.sh"
cp "$LIB" "$WORK/scripts/lib/flutter-test-env.sh"
cp "$REPO_DIR/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" \
  "$WORK/apk-staging/res/mipmap-xxxhdpi-v4/ic_launcher.png"

# Minimal zip APK with packaged launcher icon for adb pull simulation.
python3 - "$WORK/apk-staging" "$WORK/build/app/outputs/flutter-apk/app-debug.apk" <<'PY'
import os, sys, zipfile
base, apk = sys.argv[1], sys.argv[2]
icon = os.path.join(base, "res/mipmap-xxxhdpi-v4/ic_launcher.png")
with zipfile.ZipFile(apk, "w") as zf:
    zf.write(icon, "res/mipmap-xxxhdpi-v4/ic_launcher.png")
PY

cat > "$WORK/fake-sdk/platform-tools/adb" <<'EOF'
#!/usr/bin/env bash
PACKAGE="${ADB_TEST_PACKAGE:-com.cymonevo.smart_assistant}"
APK_PATH="${ADB_TEST_APK:?}"
REMOTE_APK="/data/app/base.apk"

case "${1:-}" in
  devices)
    echo "List of devices attached"
    echo "emulator-5554	device"
    ;;
  -s)
    shift
    shift
    exec "$0" "$@"
    ;;
  install)
    shift
    [ "${1:-}" = "-r" ] && shift
    exit 0
    ;;
  pull)
  shift
  dest="${2:-}"
  if [ "${1:-}" = "$REMOTE_APK" ] && [ -n "$dest" ]; then
    cp "$APK_PATH" "$dest"
    exit 0
  fi
  exit 1
    ;;
  shell)
    shift
    case "$*" in
      "pm path $PACKAGE")
        echo "package:$REMOTE_APK"
        exit 0
        ;;
      "cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.LAUNCHER $PACKAGE")
        echo "name=$PACKAGE/.MainActivity"
        exit 0
        ;;
      "dumpsys package $PACKAGE")
        echo "applicationInfo=ApplicationInfo{ ic_launcher }"
        exit 0
        ;;
      "input keyevent KEYCODE_HOME")
        exit 0
        ;;
      "exec-out screencap -p")
        printf '\x89PNG\r\n\x1a\n'
        exit 0
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
esac
exit 0
EOF
chmod +x "$WORK/fake-sdk/platform-tools/adb"

export ANDROID_HOME="$WORK/fake-sdk"
export ANDROID_SDK_ROOT="$WORK/fake-sdk"
export PATH="$WORK/fake-sdk/platform-tools:$PATH"
export DEVICE=emulator-5554
export APK_PATH="$WORK/build/app/outputs/flutter-apk/app-debug.apk"
export ADB_TEST_APK="$APK_PATH"
export ADB_TEST_PACKAGE=com.cymonevo.smart_assistant

rc=0
(cd "$WORK" && bash scripts/verify-jarvis-launcher-icon-device.sh >"$WORK/out" 2>&1) || rc=$?
if [ "$rc" -ne 0 ]; then
  sed 's/^/       | /' "$WORK/out" >&2
fi
check "mock adb device verification exits 0" "$rc" 0
grep -q "PASSED" "$WORK/out" \
  || { echo "FAIL - mock run missing PASSED"; fails=$((fails + 1)); }
grep -q "MainActivity" "$WORK/out" \
  || { echo "FAIL - mock run missing MainActivity check"; fails=$((fails + 1)); }
grep -q "Jarvis coloring OK" "$WORK/out" \
  || { echo "FAIL - mock run missing color check"; fails=$((fails + 1)); }

mkdir -p "$WORK/empty-sdk/platform-tools" "$WORK/empty-sdk/emulator"
cat > "$WORK/empty-sdk/platform-tools/adb" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "devices" ]; then echo "List of devices attached"; fi
exit 0
EOF
chmod +x "$WORK/empty-sdk/platform-tools/adb"

rc=0
PATH="$WORK/empty-sdk/platform-tools:$PATH" \
  ANDROID_HOME="$WORK/empty-sdk" \
  ANDROID_SDK_ROOT="$WORK/empty-sdk" \
  DEVICE= \
  bash "$VERIFY" >"$WORK/no-device.out" 2>&1 || rc=$?
check "no device exits non-zero" "$rc" 1
if grep -q "start-shared-emulator.sh" "$WORK/no-device.out" \
  || grep -q "No adb device" "$WORK/no-device.out" \
  || grep -q "Emulator process" "$WORK/no-device.out"; then
  echo "ok   - no-device output mentions emulator setup"
else
  echo "FAIL - no-device output missing emulator hint"
  fails=$((fails + 1))
fi

if [ "$fails" -gt 0 ]; then
  echo "$fails test(s) failed"
  exit 1
fi

echo "PASS verify-jarvis-launcher-icon-device.test.sh"
