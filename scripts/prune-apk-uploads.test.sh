#!/usr/bin/env bash
# Regression test for scripts/prune-apk-uploads.sh retention logic.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PRUNE="$SCRIPT_DIR/prune-apk-uploads.sh"
[ -f "$PRUNE" ] || { echo "FAIL: prune-apk-uploads.sh not found"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/scripts" "$WORK/bin" "$WORK/state"
cp "$PRUNE" "$WORK/scripts/prune-apk-uploads.sh"

cat > "$WORK/pubspec.yaml" <<'EOF'
name: luna_pos
version: 1.0.0+1
EOF

cat > "$WORK/bin/rclone" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
STATE="${RCLONE_TEST_STATE:?missing state dir}"
cmd="${1:-}"
shift || true
case "$cmd" in
lsf)
	remote="${1:?}"
	dir="${remote#nextcloud:APP/RELEASES/luna_pos/debug/}"
	dir="${dir%/}"
	if [ "$dir" != "APP/RELEASES/luna_pos/debug" ] && [ "$remote" != "nextcloud:APP/RELEASES/luna_pos/debug" ]; then
		exit 1
	fi
	if [ -f "$STATE/files.lst" ]; then cat "$STATE/files.lst"; fi
	exit 0
	;;
deletefile)
	remote="${1:?}"
	file="${remote##*/}"
	grep -qxF "$file" "$STATE/files.lst" || exit 1
	grep -vxF "$file" "$STATE/files.lst" > "$STATE/files.lst.tmp"
	mv "$STATE/files.lst.tmp" "$STATE/files.lst"
	printf 'deleted:%s\n' "$file" >> "$STATE/deleted.log"
	exit 0
	;;
*)
	echo "unexpected rclone command: $cmd" >&2
	exit 99
	;;
esac
EOF
chmod +x "$WORK/bin/rclone"

cat > "$WORK/state/files.lst" <<'EOF'
luna_pos-v1.0.0+1-debug-20260701-120000.apk
luna_pos-v1.0.0+1-debug-abc1234-20260702-120000.apk
luna_pos-v1.0.0+1-debug-20260703-120000.apk
luna_pos-v1.0.0+1-debug-20260704-120000.apk
EOF

: > "$WORK/state/deleted.log"

(
	cd "$WORK"
	PATH="$WORK/bin:$PATH" \
		RCLONE_TEST_STATE="$WORK/state" \
		NEXTCLOUD_BASE_DIR=APP/RELEASES \
		APK_RETENTION_COUNT=2 \
		bash scripts/prune-apk-uploads.sh debug
)

remaining="$(tr '\n' ' ' < "$WORK/state/files.lst" | sed 's/ $//')"
deleted="$(tr '\n' ' ' < "$WORK/state/deleted.log" | sed 's/ $//')"

fails=0
if [ "$remaining" = "luna_pos-v1.0.0+1-debug-20260703-120000.apk luna_pos-v1.0.0+1-debug-20260704-120000.apk" ]; then
	echo "ok   - kept two newest APKs by extracted timestamp"
else
	echo "FAIL - unexpected remaining files: [$remaining]"; fails=$((fails + 1))
fi

if [ "$deleted" = "deleted:luna_pos-v1.0.0+1-debug-20260701-120000.apk deleted:luna_pos-v1.0.0+1-debug-abc1234-20260702-120000.apk" ]; then
	echo "ok   - deleted oldest APKs by timestamp (including legacy sha names)"
else
	echo "FAIL - unexpected deletions: [$deleted]"; fails=$((fails + 1))
fi

if [ "$fails" -gt 0 ]; then exit 1; fi
echo "all prune-apk-uploads tests passed"
