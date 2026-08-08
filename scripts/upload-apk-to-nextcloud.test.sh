#!/usr/bin/env bash
# Regression test for scripts/upload-apk-to-nextcloud.sh filename construction.
#
# The uploaded APK name must be NAME-SORTABLE so the mobile/web Nextcloud clients
# (which can only sort by name) surface the latest build last: a constant prefix
# followed by a trailing UTC timestamp, with NO git sha embedded (a sha between
# the build type and the timestamp would break lexical == chronological order).
#
# This runs the REAL upload script against mocked `rclone` (no network) and a
# throwaway pubspec, then asserts the emitted remote path.
#
# Run:  bash scripts/upload-apk-to-nextcloud.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
UPLOAD="$SCRIPT_DIR/upload-apk-to-nextcloud.sh"
[ -f "$UPLOAD" ] || { echo "FAIL: upload-apk-to-nextcloud.sh not found next to test"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/scripts" "$WORK/bin"
cp "$UPLOAD" "$WORK/scripts/upload-apk-to-nextcloud.sh"
cp "$SCRIPT_DIR/prune-apk-uploads.sh" "$WORK/scripts/prune-apk-uploads.sh"

# Minimal pubspec the script parses for name + version.
cat > "$WORK/pubspec.yaml" <<'EOF'
name: luna_pos
version: 1.0.0+1
EOF

# A fake built artifact to "upload".
APK="$WORK/app-debug.apk"
: > "$APK"

# Mock rclone so the script never touches the network.
cat > "$WORK/bin/rclone" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$WORK/bin/rclone"

fails=0
check() { # desc, condition-already-evaluated? -> use string compare
	if [ "$2" = "$3" ]; then echo "ok   - $1"; else
		echo "FAIL - $1: got [$2], want [$3]"; fails=$((fails + 1)); fi
}

REMOTE_PATH="$(PATH="$WORK/bin:$PATH" bash "$WORK/scripts/upload-apk-to-nextcloud.sh" "$APK" debug 2>/dev/null | tail -n1)"

# 1. Exact shape: luna_pos/debug/luna_pos-v1.0.0+1-debug-YYYYMMDD-HHMMSS.apk
if [[ "$REMOTE_PATH" =~ ^luna_pos/debug/luna_pos-v1\.0\.0\+1-debug-[0-9]{8}-[0-9]{6}\.apk$ ]]; then
	echo "ok   - filename is name-sortable with a trailing timestamp"
else
	echo "FAIL - unexpected remote path: [$REMOTE_PATH]"; fails=$((fails + 1))
fi

# 2. No git sha embedded (guards against re-adding SHORT_SHA before the stamp).
if printf '%s' "$REMOTE_PATH" | grep -Eq -- '-debug-[0-9a-f]{7}-'; then
	echo "FAIL - a git sha segment is present in [$REMOTE_PATH]"; fails=$((fails + 1))
else
	echo "ok   - no git sha embedded in the filename"
fi

# 3. release build type is honored (folder + name).
REMOTE_REL="$(PATH="$WORK/bin:$PATH" bash "$WORK/scripts/upload-apk-to-nextcloud.sh" "$APK" release 2>/dev/null | tail -n1)"
if [[ "$REMOTE_REL" =~ ^luna_pos/release/luna_pos-v1\.0\.0\+1-release-[0-9]{8}-[0-9]{6}\.apk$ ]]; then
	echo "ok   - release build named/placed correctly"
else
	echo "FAIL - unexpected release remote path: [$REMOTE_REL]"; fails=$((fails + 1))
fi

if [ "$fails" -gt 0 ]; then echo "$fails test(s) failed"; exit 1; fi
echo "all upload-apk-to-nextcloud naming tests passed"
