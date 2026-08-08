#!/usr/bin/env bash
# Regression test for scripts/apk-build-config.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/apk-build-config.sh"
[ -f "$CONFIG" ] || { echo "FAIL: apk-build-config.sh not found"; exit 1; }

fails=0
check() {
	local desc="$1" got="$2" want="$3"
	if [ "$got" = "$want" ]; then
		echo "ok   - $desc"
	else
		echo "FAIL - $desc: got [$got], want [$want]"; fails=$((fails + 1))
	fi
}

check "explicit debug" "$(bash "$CONFIG" debug)" "debug"
check "explicit release" "$(bash "$CONFIG" release)" "release"
check "default without arg" "$(bash "$CONFIG")" "debug"
check "APK_BUILD_TYPE env" "$(APK_BUILD_TYPE=release bash "$CONFIG")" "release"
check "explicit arg beats env" "$(APK_BUILD_TYPE=release bash "$CONFIG" debug)" "debug"

if [ "$fails" -gt 0 ]; then
	echo "$fails test(s) failed"; exit 1
fi
echo "all apk-build-config tests passed"
