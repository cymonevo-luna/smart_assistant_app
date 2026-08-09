#!/usr/bin/env bash
# Unit tests for scripts/verify-assistant-widget-device.sh (no device required).
#
# Run: bash scripts/verify-assistant-widget-device.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
VERIFY="$SCRIPT_DIR/verify-assistant-widget-device.sh"
LIB="$SCRIPT_DIR/lib/flutter-test-env.sh"

[ -f "$VERIFY" ] || { echo "FAIL: verify-assistant-widget-device.sh missing"; exit 1; }
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
  shellcheck "$VERIFY" "$SCRIPT_DIR/verify-assistant-widget-device.test.sh"
  echo "ok   - shellcheck"
else
  echo "ok   - shellcheck skipped (not installed)"
fi

help_out="$(bash "$VERIFY" --help 2>&1)"
printf '%s' "$help_out" | grep -q "verify-assistant-widget-device.sh" \
  || { echo "FAIL - --help missing script name"; fails=$((fails + 1)); }
printf '%s' "$help_out" | grep -q "DEVICE" \
  || { echo "FAIL - --help missing DEVICE"; fails=$((fails + 1)); }
if [ "$fails" -eq 0 ]; then
  echo "ok   - --help documents usage"
fi

mkdir -p "$WORK/fake-sdk/platform-tools" "$WORK/fake-sdk/emulator" \
  "$WORK/build/app/outputs/flutter-apk" "$WORK/scripts/lib" "$WORK/sdcard"

cp "$VERIFY" "$WORK/scripts/verify-assistant-widget-device.sh"
cp "$LIB" "$WORK/scripts/lib/flutter-test-env.sh"
touch "$WORK/build/app/outputs/flutter-apk/app-debug.apk"

STATE_FILE="$WORK/state"

cat > "$WORK/fake-sdk/platform-tools/adb" <<'EOF'
#!/usr/bin/env bash
STATE_FILE="${ADB_TEST_STATE:?}"
PACKAGE="${ADB_TEST_PACKAGE:-com.cymonevo.smart_assistant}"
LOG_FILE="${ADB_TEST_LOG:-/dev/null}"

read_state() {
  foreground=main
  if [ -f "$STATE_FILE" ]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
  fi
}

write_state() {
  printf 'foreground=%s\nlast_uri=%s\n' "$foreground" "$last_uri" >"$STATE_FILE"
}

case "${1:-}" in
  devices)
    echo "List of devices attached"
    echo "emulator-5554	device"
    ;;
  -s)
    shift
    export ADB_SERIAL="$1"
    shift
    exec "$0" "$@"
    ;;
  install)
    shift
    [ "${1:-}" = "-r" ] && shift
    exit 0
    ;;
  shell)
    shift
    read_state
    case "$*" in
      "am force-stop $PACKAGE")
        exit 0
        ;;
      "am start "*)
        if printf '%s' "$*" | grep -q 'widget-listen'; then
          foreground=main
          last_uri="smartassistant://assistant/widget-listen"
        elif printf '%s' "$*" | grep -q 'plugin-setup'; then
          foreground=main
          last_uri="smartassistant://plugin-setup/complete?status=success"
        fi
        write_state
        exit 0
        ;;
      "dumpsys activity activities")
        if [ "$foreground" = "main" ]; then
          echo "topResumedActivity=ActivityRecord{abc u0 $PACKAGE/.MainActivity t1}"
          echo "mResumedActivity: ActivityRecord{$PACKAGE/.MainActivity}"
          echo "intent={act=android.intent.action.VIEW dat=$last_uri }"
        fi
        exit 0
        ;;
      "dumpsys package $PACKAGE")
        cat <<PKG
Receiver Resolver Table:
  com.cymonevo.smart_assistant/.AssistantWidgetProvider
    meta-data: android.appwidget.provider=@xml/assistant_widget_info
    label=Jarvis
PKG
        exit 0
        ;;
      "dumpsys appwidget")
        echo "Provider{com.cymonevo.smart_assistant/.AssistantWidgetProvider}"
        echo "meta-data assistant_widget_info"
        exit 0
        ;;
      "cmd appwidget help")
        exit 0
        ;;
      "logcat -c"|"logcat -d"*)
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
export ADB_TEST_STATE="$STATE_FILE"
export ADB_TEST_PACKAGE=com.cymonevo.smart_assistant

rc=0
(cd "$WORK" && bash scripts/verify-assistant-widget-device.sh >"$WORK/out" 2>&1) || rc=$?
if [ "$rc" -ne 0 ]; then
  sed 's/^/       | /' "$WORK/out" >&2
fi
check "mock adb device verification exits 0" "$rc" 0
grep -q "PASSED" "$WORK/out" \
  || { echo "FAIL - mock run missing PASSED"; fails=$((fails + 1)); }
grep -q "widget-listen PASSED" "$WORK/out" \
  || { echo "FAIL - mock run missing widget-listen TC"; fails=$((fails + 1)); }
grep -q "plugin-setup PASSED" "$WORK/out" \
  || { echo "FAIL - mock run missing plugin-setup TC"; fails=$((fails + 1)); }
grep -q "widget picker PASSED" "$WORK/out" \
  || { echo "FAIL - mock run missing widget picker TC"; fails=$((fails + 1)); }

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
grep -q "start-shared-emulator.sh" "$WORK/no-device.out" \
  || { echo "FAIL - no-device output missing emulator hint"; fails=$((fails + 1)); }

if [ "$fails" -gt 0 ]; then
  echo "$fails test(s) failed"
  exit 1
fi

echo "PASS verify-assistant-widget-device.test.sh"
