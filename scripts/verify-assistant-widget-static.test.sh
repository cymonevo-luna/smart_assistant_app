#!/usr/bin/env bash
# Unit tests for scripts/verify-assistant-widget-static.sh (no device required).
#
# Run: bash scripts/verify-assistant-widget-static.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
VERIFY="$SCRIPT_DIR/verify-assistant-widget-static.sh"
LIB="$SCRIPT_DIR/lib/flutter-test-env.sh"
WIDGET_INFO="$SCRIPT_DIR/../android/app/src/main/res/xml/assistant_widget_info.xml"

[ -f "$VERIFY" ] || { echo "FAIL: verify-assistant-widget-static.sh missing"; exit 1; }
[ -f "$LIB" ] || { echo "FAIL: lib/flutter-test-env.sh missing"; exit 1; }
[ -f "$WIDGET_INFO" ] || { echo "FAIL: assistant_widget_info.xml missing"; exit 1; }
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
  shellcheck "$VERIFY" "$SCRIPT_DIR/verify-assistant-widget-static.test.sh"
  echo "ok   - shellcheck"
else
  echo "ok   - shellcheck skipped (not installed)"
fi

help_out="$(bash "$VERIFY" --help 2>&1)"
printf '%s' "$help_out" | grep -q "verify-assistant-widget-static.sh" \
  || { echo "FAIL - --help missing script name"; fails=$((fails + 1)); }
printf '%s' "$help_out" | grep -q "APK_PATH" \
  || { echo "FAIL - --help missing APK_PATH"; fails=$((fails + 1)); }
if [ "$fails" -eq 0 ]; then
  echo "ok   - --help documents usage"
fi

grep -q 'targetCellWidth="1"' "$WIDGET_INFO" \
  || { echo "FAIL - widget info missing 1x1 width"; fails=$((fails + 1)); }
grep -q 'resizeMode="none"' "$WIDGET_INFO" \
  || { echo "FAIL - widget info missing resizeMode=none"; fails=$((fails + 1)); }
if [ "$fails" -eq 0 ]; then
  echo "ok   - source widget_info has 1x1 + resizeMode=none"
fi

mkdir -p "$WORK/fake-sdk/build-tools/34.0.0" "$WORK/fake-sdk/platform-tools" \
  "$WORK/fake-sdk/emulator" "$WORK/build/app/outputs/flutter-apk" \
  "$WORK/scripts/lib" "$WORK/android/app/src/main/res/xml"

cp "$VERIFY" "$WORK/scripts/verify-assistant-widget-static.sh"
cp "$LIB" "$WORK/scripts/lib/flutter-test-env.sh"
cp "$WIDGET_INFO" "$WORK/android/app/src/main/res/xml/assistant_widget_info.xml"
touch "$WORK/build/app/outputs/flutter-apk/app-debug.apk"

cat > "$WORK/fake-sdk/build-tools/34.0.0/aapt" <<'EOF'
#!/usr/bin/env bash
APK="${AAPT_TEST_APK:?}"
case "${1:-}" in
  dump)
    shift
    case "${1:-}" in
      xmltree)
        shift
        [ "${1:-}" = "$APK" ] && shift
        cat <<'MANIFEST'
      E: manifest
        E: application
          E: activity
            E: intent-filter
              E: data (line=1)
                A: android:scheme="smartassistant"
                A: android:host="assistant"
                A: android:path="/widget-listen"
            E: intent-filter
              E: data
                A: android:scheme="smartassistant"
                A: android:host="plugin-setup"
                A: android:path="/complete"
          E: receiver
            A: android:name="com.cymonevo.smart_assistant.AssistantWidgetProvider"
            A: android:exported(0x01010010)=(type 0x12)0xffffffff
            E: intent-filter
              E: action
                A: android:name="android.appwidget.action.APPWIDGET_UPDATE"
MANIFEST
        exit 0
        ;;
      badging)
        echo "package: name='com.cymonevo.smart_assistant'"
        echo "application-label:'Jarvis'"
        exit 0
        ;;
    esac
    ;;
  list)
    echo "res/layout/assistant_widget.xml"
    echo "res/xml/assistant_widget_info.xml"
    echo "res/drawable/ic_widget_mic.xml"
    exit 0
    ;;
esac
exit 1
EOF
chmod +x "$WORK/fake-sdk/build-tools/34.0.0/aapt"

export ANDROID_HOME="$WORK/fake-sdk"
export ANDROID_SDK_ROOT="$WORK/fake-sdk"
export PATH="$WORK/fake-sdk/build-tools/34.0.0:$PATH"
export APK_PATH="$WORK/build/app/outputs/flutter-apk/app-debug.apk"
export AAPT_TEST_APK="$APK_PATH"

rc=0
(cd "$WORK" && bash scripts/verify-assistant-widget-static.sh >"$WORK/out" 2>&1) || rc=$?
if [ "$rc" -ne 0 ]; then
  sed 's/^/       | /' "$WORK/out" >&2
fi
check "mock aapt static verification exits 0" "$rc" 0
grep -q "PASSED" "$WORK/out" \
  || { echo "FAIL - mock run missing PASSED"; fails=$((fails + 1)); }

mkdir -p "$WORK/empty-sdk/platform-tools" "$WORK/empty-sdk/emulator"
rc=0
ANDROID_HOME="$WORK/empty-sdk" ANDROID_SDK_ROOT="$WORK/empty-sdk" \
  bash "$VERIFY" >"$WORK/no-sdk.out" 2>&1 || rc=$?
check "missing SDK exits non-zero" "$rc" 1

if [ "$fails" -gt 0 ]; then
  echo "$fails test(s) failed"
  exit 1
fi

echo "PASS verify-assistant-widget-static.test.sh"
