#!/usr/bin/env bash
# Shared Flutter/Android test environment helpers for Luna agent runs.
# Sourced by ensure-flutter-test-env.sh, start-shared-emulator.sh, etc.

_flutter_test_env_log() { printf '>> %s\n' "$*" >&2; }

# Fixed shared AVD for all Luna agent device tests (Nexus 5X, API 34, 1536 MB, 1 core).
# Do not override — agents must use this emulator only.
SHARED_AVD="Luna_Test_Lite"
SHARED_EMULATOR_MEMORY_MB=1536
SHARED_EMULATOR_CORES=1
readonly SHARED_AVD SHARED_EMULATOR_MEMORY_MB SHARED_EMULATOR_CORES

: "${FLUTTER_BIN:=flutter}"
: "${ANDROID_HOME:=${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
: "${ANDROID_SDK_ROOT:=$ANDROID_HOME}"

LUNA_EMULATOR_STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/luna-shared-emulator"
LUNA_EMULATOR_PID_FILE="$LUNA_EMULATOR_STATE_DIR/emulator.pid"
LUNA_EMULATOR_DEVICE_FILE="$LUNA_EMULATOR_STATE_DIR/device.id"

export_flutter_test_paths() {
  export ANDROID_HOME ANDROID_SDK_ROOT
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
}

resolve_flutter_bin() {
  if command -v "$FLUTTER_BIN" >/dev/null 2>&1; then
    return 0
  fi
  if [ -x /snap/bin/flutter ]; then
    FLUTTER_BIN=/snap/bin/flutter
    export FLUTTER_BIN
    return 0
  fi
  return 1
}

resolve_android_sdk() {
  if [ -d "$ANDROID_HOME/platform-tools" ] && [ -d "$ANDROID_HOME/emulator" ]; then
    export_flutter_test_paths
    return 0
  fi
  return 1
}

kvm_usable() {
  [ -r /dev/kvm ] && [ -w /dev/kvm ]
}

kvm_group_member() {
  id -nG 2>/dev/null | grep -qw kvm \
    || getent group kvm 2>/dev/null | grep -qE "(^|:)${USER}(,|$)"
}

kvm_device_exists() {
  [ -e /dev/kvm ]
}

# Returns 0 when sg kvm can grant read/write access to /dev/kvm (stale-session workaround).
sg_kvm_grants_access() {
  kvm_device_exists || return 1
  kvm_group_member || return 1
  sg kvm -c 'test -r /dev/kvm && test -w /dev/kvm' 2>/dev/null
}

kvm_status_message() {
  if kvm_usable; then
    echo "KVM acceleration is available."
    return 0
  fi
  if kvm_group_member; then
    if kvm_device_exists && ! sg_kvm_grants_access; then
      echo "KVM acceleration is unavailable in this environment (/dev/kvm is not writable)."
      echo "The shared emulator will use software rendering (slow)."
      return 1
    fi
    echo "KVM group membership is set but this shell cannot access /dev/kvm yet."
    echo "Log out and back in (or restart the user session) so the kvm group applies."
    return 1
  fi
  echo "KVM is not writable for this user (/dev/kvm). Emulators will be slow."
  echo "Add your user to the kvm group, then log out and back in:"
  echo "  sudo usermod -aG kvm \"\$USER\""
  return 1
}

emulator_gpu_flag() {
  if kvm_usable; then
    echo "-gpu auto"
  else
    echo "-gpu swiftshader_indirect"
  fi
}

emulator_accel_flag() {
  if kvm_usable; then
    echo ""
  else
    echo "-accel off"
  fi
}

# Run a command with KVM device access when sg kvm can actually grant /dev/kvm access.
run_with_kvm() {
  if kvm_usable; then
    "$@"
    return $?
  fi
  if sg_kvm_grants_access; then
    sg kvm -c "$(printf '%q ' "$@")"
    return $?
  fi
  "$@"
}

adb_bin() {
  command -v adb 2>/dev/null || echo "$ANDROID_HOME/platform-tools/adb"
}

emulator_bin() {
  command -v emulator 2>/dev/null || echo "$ANDROID_HOME/emulator/emulator"
}

list_running_emulator_serials() {
  "$(adb_bin)" devices 2>/dev/null | awk '/^emulator-[0-9]+[[:space:]]+device$/ { print $1 }'
}

list_offline_emulator_serials() {
  "$(adb_bin)" devices 2>/dev/null | awk '/^emulator-[0-9]+[[:space:]]+offline$/ { print $1 }'
}

list_emulator_serials() {
  "$(adb_bin)" devices 2>/dev/null | awk '/^emulator-[0-9]+[[:space:]]/ { print $1 }'
}

pick_running_emulator_serial() {
  list_running_emulator_serials | head -n1
}

pick_emulator_serial() {
  list_emulator_serials | head -n1
}

adb_device_state() {
  local serial="$1"
  local state=""
  state="$("$(adb_bin)" devices 2>/dev/null | awk -v serial="$serial" '$1 == serial { print $2; exit }')"
  case "$state" in
    device | offline | authorizing) printf '%s' "$state" ;;
    *) printf '' ;;
  esac
}

wait_for_adb_device_online() {
  local serial="$1"
  local timeout="${2:-420}"
  local elapsed=0
  local offline_elapsed=0
  local recovery_done=0
  local state=""

  _flutter_test_env_log "Waiting for $serial adb online (timeout ${timeout}s)..."
  while true; do
    state="$(adb_device_state "$serial")"
    if [ "$state" = "device" ]; then
      _flutter_test_env_log "$serial is adb online."
      return 0
    fi

    if [ "$state" = "offline" ]; then
      offline_elapsed=$((offline_elapsed + 2))
      if [ "$offline_elapsed" -ge 30 ] && [ "$recovery_done" -eq 0 ]; then
        _flutter_test_env_log "$serial adb offline for ${offline_elapsed}s; restarting adb server..."
        "$(adb_bin)" kill-server 2>/dev/null || true
        "$(adb_bin)" start-server 2>/dev/null || true
        recovery_done=1
        state="$(adb_device_state "$serial")"
        if [ "$state" = "device" ]; then
          _flutter_test_env_log "$serial is adb online."
          return 0
        fi
      fi
    fi

    if [ "$elapsed" -ge "$timeout" ]; then
      break
    fi

    sleep 2
    elapsed=$((elapsed + 2))
  done

  state="$(adb_device_state "$serial")"
  if [ "$state" = "device" ]; then
    _flutter_test_env_log "$serial is adb online."
    return 0
  fi

  _flutter_test_env_log "ERROR: Timed out waiting for $serial adb online (observed state: ${state:-none})."
  kvm_status_message >&2 || true
  _flutter_test_env_log "Run scripts/ensure-flutter-test-env.sh for a full environment report."
  _flutter_test_env_log "If KVM is unavailable, fix host access: sudo usermod -aG kvm \"\$USER\" (then log out and back in)."
  return 1
}

emulator_boot_completed() {
  local serial="$1"
  [ "$("$(adb_bin)" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]
}

wait_for_emulator_boot() {
  local serial="$1"
  local timeout="${2:-300}"
  local elapsed=0
  _flutter_test_env_log "Waiting for $serial to finish booting (timeout ${timeout}s)..."
  while [ "$elapsed" -lt "$timeout" ]; do
    if emulator_boot_completed "$serial"; then
      _flutter_test_env_log "$serial is ready."
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  _flutter_test_env_log "Timed out waiting for $serial to boot."
  return 1
}

ensure_state_dir() {
  mkdir -p "$LUNA_EMULATOR_STATE_DIR"
}

record_shared_emulator() {
  local pid="$1"
  local serial="$2"
  ensure_state_dir
  printf '%s\n' "$pid" >"$LUNA_EMULATOR_PID_FILE"
  printf '%s\n' "$serial" >"$LUNA_EMULATOR_DEVICE_FILE"
}

read_shared_emulator_serial() {
  if [ -f "$LUNA_EMULATOR_DEVICE_FILE" ]; then
    tr -d '\r\n' <"$LUNA_EMULATOR_DEVICE_FILE"
    return 0
  fi
  pick_running_emulator_serial
}

shared_emulator_pid_alive() {
  local pid=""
  [ -f "$LUNA_EMULATOR_PID_FILE" ] || return 1
  pid="$(tr -d '\r\n' <"$LUNA_EMULATOR_PID_FILE")"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}
