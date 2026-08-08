#!/usr/bin/env bash
# Regression test for scripts/build-apk.sh codegen retry logic.
#
# build_runner (freezed/json_serializable) intermittently deadlocks: it makes
# progress then hangs until killed. build-apk.sh therefore runs codegen under a
# short per-attempt timeout and retries, failing fast only on genuine errors.
# This test exercises that behavior by running the REAL build-apk.sh against
# mocked `flutter`/`dart` binaries (no Flutter SDK required).
#
# Run:  bash scripts/build-apk.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
BUILD_APK="$SCRIPT_DIR/build-apk.sh"
[ -f "$BUILD_APK" ] || { echo "FAIL: build-apk.sh not found next to test"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/scripts" "$WORK/bin"
cp "$BUILD_APK" "$WORK/scripts/build-apk.sh"
: > "$WORK/.env"

cat > "$WORK/bin/flutter" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  pub)   exit 0 ;;
  build) mkdir -p build/app/outputs/flutter-apk
         if printf '%s\n' "$@" | grep -q -- '--split-per-abi'; then
           : > build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
         else
           : > build/app/outputs/flutter-apk/app-debug.apk
           : > build/app/outputs/flutter-apk/app-release.apk
         fi
         exit 0 ;;
esac
EOF
chmod +x "$WORK/bin/flutter"

# $1 = "succeed-on-N" | "error" | "hang". Uses BR_COUNTER_FILE to track attempts.
write_dart_mock() {
	case "$1" in
	succeed-on-*)
		local on="${1##succeed-on-}"
		cat > "$WORK/bin/dart" <<EOF
#!/usr/bin/env bash
C="\$BR_COUNTER_FILE"; n=\$(cat "\$C" 2>/dev/null || echo 0); n=\$((n+1)); echo "\$n" > "\$C"
if [ "\$n" -lt $on ]; then sleep 60; fi
exit 0
EOF
		;;
	error) printf '#!/usr/bin/env bash\nexit 1\n' > "$WORK/bin/dart" ;;
	hang) printf '#!/usr/bin/env bash\nsleep 60\n' > "$WORK/bin/dart" ;;
	esac
	chmod +x "$WORK/bin/dart"
}

run_case() {
	rm -f "$WORK/counter"
	local rc=0
	PATH="$WORK/bin:$PATH" \
		BR_COUNTER_FILE="$WORK/counter" \
		BUILD_RUNNER_TIMEOUT=2 BUILD_RUNNER_ATTEMPTS="${ATTEMPTS:-3}" \
		bash "$WORK/scripts/build-apk.sh" debug >"$WORK/out" 2>&1 || rc=$?
	echo "$rc"
}

fails=0
check() { # desc, got, want
	if [ "$2" = "$3" ]; then
		echo "ok   - $1"
	else
		echo "FAIL - $1: got exit $2, want $3"; sed 's/^/       | /' "$WORK/out"; fails=$((fails + 1))
	fi
}

# 1. Deadlocks once, then a fresh run succeeds -> retry recovers (exit 0).
write_dart_mock succeed-on-2
check "retries a transient codegen deadlock and succeeds" "$(run_case)" 0

# 2. Genuine codegen error -> fail fast, no retry (exit 1).
write_dart_mock error
check "fails fast on a real codegen error" "$(run_case)" 1

# 3. Deadlocks every attempt -> gives up after N attempts (exit 124).
write_dart_mock hang
ATTEMPTS=2 check "gives up after exhausting attempts" "$(run_case)" 124

# 4. Release + APK_SPLIT_ABI selects the arm64-v8a split artifact.
rc=0
apk_path=""
PATH="$WORK/bin:$PATH" SKIP_CODEGEN=1 APK_SPLIT_ABI=1 bash "$WORK/scripts/build-apk.sh" release >"$WORK/out" 2>&1 || rc=$?
apk_path="$(tail -n1 "$WORK/out" 2>/dev/null || true)"
if [ "$rc" -eq 0 ] && [ "$apk_path" = "$WORK/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]; then
	echo "ok   - release split-per-abi returns arm64-v8a artifact path"
else
	echo "FAIL - release split-per-abi: exit=$rc path=[$apk_path]"; sed 's/^/       | /' "$WORK/out"; fails=$((fails + 1))
fi

if [ "$fails" -gt 0 ]; then
	echo "$fails test(s) failed"; exit 1
fi
echo "all build-apk codegen-retry tests passed"
