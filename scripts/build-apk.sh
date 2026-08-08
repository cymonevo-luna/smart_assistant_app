#!/usr/bin/env bash
# Build the Android .apk for this Flutter app.
#
# Self-locating: lives in <repo>/scripts/ and resolves the repo root as its
# parent, so it works the same locally and on the Jenkins deploy host.
#
# Usage:
#   scripts/build-apk.sh [debug|release]   # default: debug
#
# On success the ABSOLUTE path to the built .apk is printed on the LAST stdout
# line (everything else is logged to stderr) so callers can capture it with:
#   APK="$(scripts/build-apk.sh release | tail -n1)"
#
# Env overrides:
#   FLUTTER_BIN            flutter executable (default: flutter on PATH)
#   SKIP_CODEGEN           set to 1 to skip `dart run build_runner build`
#   BUILD_RUNNER_TIMEOUT   seconds before a codegen ATTEMPT is killed (default: 600)
#   BUILD_RUNNER_ATTEMPTS  codegen attempts before giving up (default: 3); codegen
#                          intermittently deadlocks and a fresh run clears it
#   APK_SPLIT_ABI          set to 1 for release builds to use --split-per-abi and
#                          ship the APK_TARGET_ABI slice (smaller than a fat apk)
#   APK_TARGET_ABI         abi slice to return when APK_SPLIT_ABI=1 (default: arm64-v8a)
set -euo pipefail

log() { printf '>> %s\n' "$*" >&2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# build_runner uses a single-instance lock per package dir. After an aborted
# Jenkins deploy the lock file can outlive the dead process and block forever.
ensure_build_runner_unlocked() {
	local lock="$REPO_DIR/.dart_tool/build/lock/build_runner.lock"
	[ -f "$lock" ] || return 0

	local lock_pid=""
	lock_pid="$(tr -d '[:space:]' < "$lock" 2>/dev/null || true)"
	if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
		local lock_cwd=""
		lock_cwd="$(readlink -f "/proc/$lock_pid/cwd" 2>/dev/null || true)"
		if [ "$lock_cwd" = "$REPO_DIR" ]; then
			log "build_runner lock held by live PID $lock_pid; leaving lock in place"
			return 0
		fi
	fi

	log "Removing stale build_runner lock at $lock"
	rm -f "$lock"
}

# Kill any build_runner/codegen process still running out of THIS repo dir — a
# deadlocked run the timeout could not fully reap (build_runner spawns child
# analyzer/frontend_server processes that can outlive the parent and keep holding
# the single-instance lock). Scoped to REPO_DIR so it never touches other apps.
kill_stale_build_runner() {
	local pid cwd
	for pid in $(pgrep -u "$(id -u)" -f 'build_runner|frontend_server|dartaotruntime' 2>/dev/null || true); do
		[ -n "$pid" ] || continue
		[ "$pid" = "$$" ] && continue
		cwd="$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)"
		[ "$cwd" = "$REPO_DIR" ] || continue
		kill -KILL "$pid" 2>/dev/null || true
	done
}

# Codegen (freezed/json_serializable via build_runner) occasionally DEADLOCKS in
# the analyzer: it makes some progress, then hangs indefinitely until killed
# (observed on deploy-luna_pos_app #18, which sat idle for the full 30-minute
# timeout). A fresh invocation almost always clears it (#19 codegen finished the
# same models in ~16s). So run codegen under a SHORT per-attempt timeout and
# retry a few times, tearing down the hung run and clearing its lock between
# attempts. A genuine codegen error (any non-timeout exit) fails fast — retrying
# it would only repeat the same failure and waste the deploy window.
run_build_runner() {
	local attempt_timeout="${BUILD_RUNNER_TIMEOUT:-600}"
	local attempts="${BUILD_RUNNER_ATTEMPTS:-3}"
	local n=0 rc=0

	while :; do
		n=$((n + 1))
		rc=0
		log "dart run build_runner build (code generation, attempt ${n}/${attempts}, timeout ${attempt_timeout}s)"
		# `|| rc=$?` captures the exit code without tripping `set -e` (a bare
		# failing command would abort the script before we could decide to retry).
		if command -v timeout >/dev/null 2>&1; then
			# -k 30: if build_runner ignores SIGTERM, SIGKILL it 30s later so a
			# deadlocked run cannot survive as an orphan holding the lock.
			timeout -k 30 "$attempt_timeout" dart run build_runner build --delete-conflicting-outputs >&2 || rc=$?
		else
			dart run build_runner build --delete-conflicting-outputs >&2 || rc=$?
		fi

		[ "$rc" -eq 0 ] && return 0

		# 124 = timed out (SIGTERM); 137 = SIGKILL after -k. Both mean the
		# deadlock — anything else is a real codegen error, so fail fast.
		if [ "$rc" -ne 124 ] && [ "$rc" -ne 137 ]; then
			log "build_runner failed (exit $rc); not a timeout — aborting without retry"
			return "$rc"
		fi
		if [ "$n" -ge "$attempts" ]; then
			log "build_runner still deadlocking after $n attempt(s) (exit $rc); giving up"
			return "$rc"
		fi

		log "build_runner timed out (exit $rc, attempt $n/$attempts); tearing down and retrying ..."
		kill_stale_build_runner
		ensure_build_runner_unlocked
		sleep 3
	done
}

BUILD_TYPE="${1:-debug}"
case "$BUILD_TYPE" in
	debug|release) ;;
	*)
		echo "ERROR: build type must be 'debug' or 'release' (got '$BUILD_TYPE')" >&2
		exit 2
		;;
esac

FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
command -v "$FLUTTER_BIN" >/dev/null 2>&1 || {
	echo "ERROR: '$FLUTTER_BIN' not found on PATH. Install the Flutter SDK or set FLUTTER_BIN." >&2
	exit 1
}

# The template ships `.env` as a bundled asset (see pubspec.yaml). A build fails
# if it is missing, so make sure SOMETHING is there (the deploy host stages the
# real per-app .env before calling this; locally we fall back to .env.example).
if [ ! -f .env ]; then
	if [ -f .env.example ]; then
		log "No .env found; copying .env.example so the asset bundle resolves."
		cp .env.example .env
	else
		log "WARN: no .env or .env.example present; build may fail on the .env asset."
	fi
fi

log "flutter pub get"
"$FLUTTER_BIN" pub get >&2

# freezed / json_serializable models need generated code before the build.
if [ "${SKIP_CODEGEN:-0}" != "1" ]; then
	ensure_build_runner_unlocked
	run_build_runner
fi

APK_OUTPUT_DIR="$REPO_DIR/build/app/outputs/flutter-apk"
SPLIT_ABI=0
if [ "$BUILD_TYPE" = "release" ] && [ "${APK_SPLIT_ABI:-1}" = "1" ]; then
	SPLIT_ABI=1
fi
if [ "$SPLIT_ABI" = "1" ]; then
	TARGET_ABI="${APK_TARGET_ABI:-arm64-v8a}"
	log "flutter build apk --release --split-per-abi (artifact: app-${TARGET_ABI}-release.apk)"
	"$FLUTTER_BIN" build apk --release --split-per-abi >&2
	APK_PATH="$APK_OUTPUT_DIR/app-${TARGET_ABI}-release.apk"
else
	log "flutter build apk --$BUILD_TYPE"
	"$FLUTTER_BIN" build apk "--$BUILD_TYPE" >&2
	APK_PATH="$APK_OUTPUT_DIR/app-$BUILD_TYPE.apk"
fi
[ -f "$APK_PATH" ] || {
	echo "ERROR: expected APK not found at $APK_PATH" >&2
	exit 1
}

log "Built $BUILD_TYPE APK: $APK_PATH"
# Last stdout line = the artifact path (machine-readable for callers).
printf '%s\n' "$APK_PATH"
