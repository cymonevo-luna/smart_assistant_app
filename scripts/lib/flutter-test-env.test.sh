#!/usr/bin/env bash
# Regression tests for scripts/lib/flutter-test-env.sh (no real emulator required).
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
LIB="$SCRIPT_DIR/flutter-test-env.sh"

[ -f "$LIB" ] || { echo "FAIL: lib/flutter-test-env.sh missing"; exit 1; }

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

mkdir -p "$WORK/fake-sdk/platform-tools" "$WORK/fake-sdk/emulator"

run_with_fake_adb() {
  local adb_script="$1"
  shift
  (
    export ANDROID_HOME="$WORK/fake-sdk"
    export ANDROID_SDK_ROOT="$WORK/fake-sdk"
    export PATH="$WORK/fake-sdk/platform-tools:$PATH"
    cp "$adb_script" "$WORK/fake-sdk/platform-tools/adb"
    chmod +x "$WORK/fake-sdk/platform-tools/adb"
    # shellcheck source=flutter-test-env.sh
    source "$LIB"
    "$@"
  )
}

# --- adb_device_state ---

cat > "$WORK/adb-multi" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "devices" ]; then
  echo "List of devices attached"
  echo "emulator-5554	device"
  echo "emulator-5556	offline"
  echo "emulator-5558	authorizing"
fi
exit 0
EOF

check "adb_device_state device" \
  "$(run_with_fake_adb "$WORK/adb-multi" adb_device_state emulator-5554)" "device"
check "adb_device_state offline" \
  "$(run_with_fake_adb "$WORK/adb-multi" adb_device_state emulator-5556)" "offline"
check "adb_device_state authorizing" \
  "$(run_with_fake_adb "$WORK/adb-multi" adb_device_state emulator-5558)" "authorizing"
check "adb_device_state missing" \
  "$(run_with_fake_adb "$WORK/adb-multi" adb_device_state emulator-9999)" ""

offline="$(run_with_fake_adb "$WORK/adb-multi" list_offline_emulator_serials | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
check "list_offline_emulator_serials" "$offline" "emulator-5556"

# --- wait_for_adb_device_online: permanently offline fails with guidance ---

cat > "$WORK/adb-offline" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "devices" ]; then
  echo "List of devices attached"
  echo "emulator-5554	offline"
fi
exit 0
EOF

set +e
offline_out="$(run_with_fake_adb "$WORK/adb-offline" wait_for_adb_device_online emulator-5554 10 2>&1)"
offline_rc=$?
set -e
check "wait_for_adb_device_online offline rc" "$offline_rc" "1"
printf '%s' "$offline_out" | grep -q "offline" \
  || { echo "FAIL - offline stderr missing offline state"; fails=$((fails + 1)); }
printf '%s' "$offline_out" | grep -qE "ensure-flutter-test-env|KVM|kvm" \
  || { echo "FAIL - offline stderr missing KVM/ensure guidance"; fails=$((fails + 1)); }
if [ "$offline_rc" -eq 1 ]; then
  echo "ok   - wait_for_adb_device_online offline guidance"
fi

# --- wait_for_adb_device_online: offline-to-online after kill-server ---

cat > "$WORK/adb-recover" <<'EOF'
#!/usr/bin/env bash
STATE_FILE="${ADB_TEST_STATE:?}"
if [ "$1" = "kill-server" ]; then
  echo "killed" >"$STATE_FILE"
  exit 0
fi
if [ "$1" = "start-server" ]; then
  exit 0
fi
if [ "$1" = "devices" ]; then
  echo "List of devices attached"
  if [ -f "$STATE_FILE" ]; then
    echo "emulator-5554	device"
  else
    echo "emulator-5554	offline"
  fi
fi
exit 0
EOF

export ADB_TEST_STATE="$WORK/adb-state"
rm -f "$ADB_TEST_STATE"

set +e
recover_out="$(
  export ADB_TEST_STATE="$WORK/adb-state"
  run_with_fake_adb "$WORK/adb-recover" wait_for_adb_device_online emulator-5554 30 2>&1
)"
recover_rc=$?
set -e
check "wait_for_adb_device_online recovery rc" "$recover_rc" "0"
[ -f "$ADB_TEST_STATE" ] \
  || { echo "FAIL - recovery did not invoke adb kill-server"; fails=$((fails + 1)); }
if [ "$recover_rc" -eq 0 ] && [ -f "$ADB_TEST_STATE" ]; then
  echo "ok   - wait_for_adb_device_online offline-to-online recovery"
fi

# --- emulator render flags (KVM group without writable device) ---

run_with_mocked_kvm() {
  local mock_kvm_usable="$1"
  local mock_kvm_group="$2"
  shift 2
  (
    # shellcheck source=flutter-test-env.sh
    source "$LIB"
    kvm_usable() { [ "$mock_kvm_usable" = true ]; }
    kvm_group_member() { [ "$mock_kvm_group" = true ]; }
    "$@"
  )
}

gpu="$(run_with_mocked_kvm false true emulator_gpu_flag)"
accel="$(run_with_mocked_kvm false true emulator_accel_flag)"
check "emulator_gpu_flag kvm group without writable kvm" "$gpu" "-gpu swiftshader_indirect"
check "emulator_accel_flag kvm group without writable kvm" "$accel" "-accel off"
if [ "$gpu" = "-gpu auto" ] && [ "$accel" != "-accel off" ]; then
  echo "FAIL - kvm group without writable kvm must not use -gpu auto without -accel off"
  fails=$((fails + 1))
else
  echo "ok   - kvm group without writable kvm avoids hardware-only flags"
fi

gpu="$(run_with_mocked_kvm true false emulator_gpu_flag)"
accel="$(run_with_mocked_kvm true false emulator_accel_flag)"
check "emulator_gpu_flag kvm usable" "$gpu" "-gpu auto"
check "emulator_accel_flag kvm usable" "$accel" ""

# --- run_with_kvm: skip sg when probe fails ---

mkdir -p "$WORK/bin"
cat > "$WORK/bin/sg" <<'EOF'
#!/usr/bin/env bash
echo "sg invoked: $*" >>"${SG_LOG:?}"
exit 1
EOF
chmod +x "$WORK/bin/sg"

export SG_LOG="$WORK/sg.log"
rm -f "$SG_LOG"

set +e
(
  # shellcheck source=flutter-test-env.sh
  source "$LIB"
  kvm_usable() { return 1; }
  kvm_group_member() { return 0; }
  sg_kvm_grants_access() { return 1; }
  export PATH="$WORK/bin:$PATH"
  run_with_kvm echo direct-run >/dev/null
)
run_rc=$?
set -e
check "run_with_kvm direct when sg probe fails rc" "$run_rc" "0"
if [ -f "$SG_LOG" ]; then
  echo "FAIL - run_with_kvm invoked sg when probe failed"
  fails=$((fails + 1))
else
  echo "ok   - run_with_kvm skips sg when probe fails"
fi

# --- kvm_status_message: container pod vs stale session ---

msg="$(
  # shellcheck source=flutter-test-env.sh
  source "$LIB"
  kvm_usable() { return 1; }
  kvm_group_member() { return 0; }
  kvm_device_exists() { return 0; }
  sg_kvm_grants_access() { return 1; }
  kvm_status_message || true
)"
printf '%s' "$msg" | grep -q "software rendering" \
  || { echo "FAIL - kvm_status_message missing software rendering for unwritable kvm"; fails=$((fails + 1)); }
printf '%s' "$msg" | grep -qi "log out" \
  && { echo "FAIL - kvm_status_message should not suggest logout for unwritable kvm in container"; fails=$((fails + 1)); } \
  || echo "ok   - kvm_status_message container pod guidance"

msg="$(
  # shellcheck source=flutter-test-env.sh
  source "$LIB"
  kvm_usable() { return 1; }
  kvm_group_member() { return 0; }
  sg_kvm_grants_access() { return 0; }
  kvm_status_message || true
)"
printf '%s' "$msg" | grep -qi "log out" \
  || { echo "FAIL - kvm_status_message missing logout guidance for stale session"; fails=$((fails + 1)); }
if printf '%s' "$msg" | grep -qi "log out"; then
  echo "ok   - kvm_status_message stale session guidance"
fi

if [ "$fails" -eq 0 ]; then
  echo "PASS flutter-test-env.test.sh"
else
  echo "FAIL flutter-test-env.test.sh ($fails failures)"
  exit 1
fi
