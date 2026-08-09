#!/usr/bin/env bash
# Unit tests for scripts/verify-jarvis-branding-static.sh (no device required).
#
# Run: bash scripts/verify-jarvis-branding-static.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
VERIFY="$SCRIPT_DIR/verify-jarvis-branding-static.sh"
LIB="$SCRIPT_DIR/lib/flutter-test-env.sh"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

[ -f "$VERIFY" ] || { echo "FAIL: verify-jarvis-branding-static.sh missing"; exit 1; }
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
  shellcheck "$VERIFY" "$SCRIPT_DIR/verify-jarvis-branding-static.test.sh"
  echo "ok   - shellcheck"
else
  echo "ok   - shellcheck skipped (not installed)"
fi

help_out="$(bash "$VERIFY" --help 2>&1)"
printf '%s' "$help_out" | grep -q "verify-jarvis-branding-static.sh" \
  || { echo "FAIL - --help missing script name"; fails=$((fails + 1)); }
printf '%s' "$help_out" | grep -q "APK_PATH" \
  || { echo "FAIL - --help missing APK_PATH"; fails=$((fails + 1)); }
if [ "$fails" -eq 0 ]; then
  echo "ok   - --help documents usage"
fi

mkdir -p "$WORK/fake-sdk/build-tools/34.0.0" "$WORK/fake-sdk/platform-tools" \
  "$WORK/fake-sdk/emulator" "$WORK/build/app/outputs/flutter-apk" \
  "$WORK/scripts/lib" \
  "$WORK/android/app/src/main/res" \
  "$WORK/web/icons" \
  "$WORK/ios/Runner/Assets.xcassets/AppIcon.appiconset" \
  "$WORK/macos/Runner/Assets.xcassets/AppIcon.appiconset" \
  "$WORK/windows/runner/resources"

cp "$VERIFY" "$WORK/scripts/verify-jarvis-branding-static.sh"
cp "$LIB" "$WORK/scripts/lib/flutter-test-env.sh"

for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  mkdir -p "$WORK/android/app/src/main/res/mipmap-${density}"
  cp "$REPO_DIR/android/app/src/main/res/mipmap-${density}/ic_launcher.png" \
    "$WORK/android/app/src/main/res/mipmap-${density}/ic_launcher.png"
done

cp "$REPO_DIR/web/favicon.png" "$WORK/web/favicon.png"
cp "$REPO_DIR/web/icons/Icon-"*.png "$WORK/web/icons/"
cp "$REPO_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/"* \
  "$WORK/ios/Runner/Assets.xcassets/AppIcon.appiconset/"
cp "$REPO_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/"* \
  "$WORK/macos/Runner/Assets.xcassets/AppIcon.appiconset/"
cp "$REPO_DIR/windows/runner/resources/app_icon.ico" \
  "$WORK/windows/runner/resources/app_icon.ico"

touch "$WORK/build/app/outputs/flutter-apk/app-debug.apk"

cat > "$WORK/fake-sdk/build-tools/34.0.0/aapt" <<'EOF'
#!/usr/bin/env bash
APK="${AAPT_TEST_APK:?}"
case "${1:-}" in
  dump)
    shift
    case "${1:-}" in
      badging)
        echo "package: name='com.cymonevo.smart_assistant'"
        echo "application-icon-160:'res/mipmap-mdpi-v4/ic_launcher.png'"
        echo "application-icon:'res/mipmap-xxxhdpi-v4/ic_launcher.png'"
        exit 0
        ;;
    esac
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
(cd "$WORK" && bash scripts/verify-jarvis-branding-static.sh >"$WORK/out" 2>&1) || rc=$?
if [ "$rc" -ne 0 ]; then
  sed 's/^/       | /' "$WORK/out" >&2
fi
check "mock aapt static verification exits 0" "$rc" 0
grep -q "PASSED" "$WORK/out" \
  || { echo "FAIL - mock run missing PASSED"; fails=$((fails + 1)); }
grep -q "mipmap launcher icons" "$WORK/out" \
  || { echo "FAIL - mock run missing mipmap check"; fails=$((fails + 1)); }
grep -q "application-icon" "$WORK/out" \
  || { echo "FAIL - mock run missing badging check"; fails=$((fails + 1)); }

mkdir -p "$WORK/empty-sdk/platform-tools" "$WORK/empty-sdk/emulator"
rc=0
ANDROID_HOME="$WORK/empty-sdk" ANDROID_SDK_ROOT="$WORK/empty-sdk" \
  bash "$VERIFY" >"$WORK/no-sdk.out" 2>&1 || rc=$?
check "missing SDK exits non-zero" "$rc" 1

if [ "$fails" -gt 0 ]; then
  echo "$fails test(s) failed"
  exit 1
fi

echo "PASS verify-jarvis-branding-static.test.sh"
