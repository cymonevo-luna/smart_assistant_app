#!/usr/bin/env bash
# Unit tests for scripts/verify-active-listening-notification.sh (no device required).
#
# Run: bash scripts/verify-active-listening-notification.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
VERIFY="$SCRIPT_DIR/verify-active-listening-notification.sh"
LIB="$SCRIPT_DIR/lib/flutter-test-env.sh"

[ -f "$VERIFY" ] || { echo "FAIL: verify-active-listening-notification.sh missing"; exit 1; }
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

# 1. Syntax check
bash -n "$VERIFY"
echo "ok   - bash -n syntax check"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$VERIFY" "$SCRIPT_DIR/verify-active-listening-notification.test.sh"
  echo "ok   - shellcheck"
else
  echo "ok   - shellcheck skipped (not installed)"
fi

# 2. --help usage
help_out="$(bash "$VERIFY" --help 2>&1)"
printf '%s' "$help_out" | grep -q "verify-active-listening-notification.sh" \
  || { echo "FAIL - --help missing script name"; fails=$((fails + 1)); }
printf '%s' "$help_out" | grep -q "DEVICE" \
  || { echo "FAIL - --help missing DEVICE"; fails=$((fails + 1)); }
if [ "$fails" -eq 0 ]; then
  echo "ok   - --help documents usage"
fi

mkdir -p "$WORK/fake-sdk/platform-tools" "$WORK/fake-sdk/emulator" "$WORK/bin" "$WORK/scripts/lib" "$WORK/build/app/outputs/flutter-apk"
cp "$VERIFY" "$WORK/scripts/verify-active-listening-notification.sh"
cp "$LIB" "$WORK/scripts/lib/flutter-test-env.sh"
touch "$WORK/build/app/outputs/flutter-apk/app-debug.apk"

STATE_FILE="$WORK/state"
NOTIF_FILE="$WORK/notification.txt"

cat > "$WORK/fake-sdk/platform-tools/adb" <<'EOF'
#!/usr/bin/env bash
STATE_FILE="${ADB_TEST_STATE:?}"
NOTIF_FILE="${ADB_TEST_NOTIF:?}"
PACKAGE="${ADB_TEST_PACKAGE:-com.cymonevo.smart_assistant}"

SDCARD_DIR="${ADB_TEST_SDCARD:-/tmp/adb-test-sdcard}"

read_state() {
  boot=0
  active=false
  installed=false
  if [ -f "$STATE_FILE" ]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
  fi
}

write_state() {
  printf 'boot=%s\nactive=%s\ninstalled=%s\n' "$boot" "$active" "$installed" >"$STATE_FILE"
}

update_notification_dump() {
  read_state
  if [ "$active" = "true" ]; then
    cat >"$NOTIF_FILE" <<NOTIF
NotificationRecord pkg=$PACKAGE
  channelId=active_listening
  title=Active listening
NOTIF
  else
    : >"$NOTIF_FILE"
  fi
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
    read_state
    installed=true
    write_state
    exit 0
    ;;
  shell)
  shift
  case "$*" in
    "pm grant "*)
      exit 0
      ;;
    "run-as $PACKAGE true")
      exit 0
      ;;
    "run-as $PACKAGE mkdir -p shared_prefs")
      exit 0
      ;;
    "run-as $PACKAGE cp /sdcard/FlutterSharedPreferences.xml shared_prefs/FlutterSharedPreferences.xml")
      prefs="$SDCARD_DIR/FlutterSharedPreferences.xml"
      if grep -q 'value="true"' "$prefs" 2>/dev/null; then
        active=true
      else
        active=false
      fi
      write_state
      update_notification_dump
      exit 0
      ;;
    "rm -f /sdcard/FlutterSharedPreferences.xml")
      rm -f "$SDCARD_DIR/FlutterSharedPreferences.xml"
      exit 0
      ;;
    "am force-stop $PACKAGE")
      exit 0
      ;;
    "am start "*)
      read_state
      boot=1
      write_state
      if [ "$active" = "true" ]; then
        update_notification_dump
      fi
      exit 0
      ;;
    "dumpsys notification --list"|"dumpsys notification")
      cat "$NOTIF_FILE" 2>/dev/null || true
      exit 0
      ;;
    "dumpsys activity services com.pravera.flutter_foreground_task.service.ForegroundService")
      read_state
      if [ "$active" = "true" ]; then
        echo "ServiceRecord pkg=$PACKAGE foregroundServiceType=microphone"
      fi
      exit 0
      ;;
    *)
      exit 0
      ;;
  esac
  ;;
  push)
    dest="$3"
    case "$dest" in
      /sdcard/*) dest="$SDCARD_DIR/${dest#/sdcard/}" ;;
    esac
    mkdir -p "$(dirname "$dest")"
    cp "$2" "$dest"
    exit 0
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
export ADB_TEST_NOTIF="$NOTIF_FILE"
export ADB_TEST_PACKAGE=com.cymonevo.smart_assistant
export ADB_TEST_SDCARD="$WORK/sdcard"

rc=0
(cd "$WORK" && bash scripts/verify-active-listening-notification.sh >"$WORK/out" 2>&1) || rc=$?
if [ "$rc" -ne 0 ]; then
  sed 's/^/       | /' "$WORK/out" >&2
fi
check "mock adb full verification exits 0" "$rc" 0
grep -q "PASSED" "$WORK/out" \
  || { echo "FAIL - mock run missing PASSED"; fails=$((fails + 1)); }

# 3. No device should fail fast with a helpful hint
mkdir -p "$WORK/empty-sdk/platform-tools" "$WORK/empty-sdk/emulator"
cat > "$WORK/empty-sdk/platform-tools/adb" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "devices" ]; then
  echo "List of devices attached"
fi
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
grep -q "ensure-flutter-test-env.sh" "$WORK/no-device.out" \
  || { echo "FAIL - no-device output missing ensure-flutter-test-env hint"; fails=$((fails + 1)); }
if [ "$fails" -eq 0 ]; then
  echo "ok   - no device prints setup hint"
fi

if [ "$fails" -gt 0 ]; then
  echo "$fails test(s) failed"
  exit 1
fi

echo "PASS verify-active-listening-notification.test.sh"
