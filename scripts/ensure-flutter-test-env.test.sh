#!/usr/bin/env bash
# Regression tests for scripts/ensure-flutter-test-env.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
ENSURE="$SCRIPT_DIR/ensure-flutter-test-env.sh"
LIB="$SCRIPT_DIR/lib/flutter-test-env.sh"

[ -f "$ENSURE" ] || { echo "FAIL: ensure-flutter-test-env.sh missing"; exit 1; }
[ -f "$LIB" ] || { echo "FAIL: lib/flutter-test-env.sh missing"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/fake-sdk/platform-tools" "$WORK/fake-sdk/emulator" "$WORK/bin"
touch "$WORK/fake-sdk/platform-tools/adb"
touch "$WORK/fake-sdk/emulator/emulator"
chmod +x "$WORK/fake-sdk/platform-tools/adb" "$WORK/fake-sdk/emulator/emulator"

cat > "$WORK/bin/flutter" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "--version" ]; then echo "Flutter 9.9.9 • channel test"; fi
exit 0
EOF
chmod +x "$WORK/bin/flutter"

cat > "$WORK/fake-sdk/platform-tools/adb" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "devices" ]; then
  echo "List of devices attached"
  echo "emulator-5554	device"
fi
exit 0
EOF
chmod +x "$WORK/fake-sdk/platform-tools/adb"

export PATH="$WORK/bin:$PATH"
export ANDROID_HOME="$WORK/fake-sdk"
export ANDROID_SDK_ROOT="$WORK/fake-sdk"
export FLUTTER_BIN=flutter

bash "$ENSURE" --check-vm >/dev/null
bash "$ENSURE" --check-device >/dev/null
exports="$(bash "$ENSURE" --export)"
eval "$exports"
[ "$ANDROID_HOME" = "$WORK/fake-sdk" ] || { echo "FAIL: export ANDROID_HOME"; exit 1; }

# shellcheck source=lib/flutter-test-env.sh
source "$LIB"
[ "$SHARED_AVD" = "Luna_Test_Lite" ] || { echo "FAIL: export SHARED_AVD must be Luna_Test_Lite"; exit 1; }

serial="$(pick_running_emulator_serial)"
[ "$serial" = "emulator-5554" ] || { echo "FAIL: expected emulator-5554 got $serial"; exit 1; }

echo "PASS ensure-flutter-test-env.test.sh"
