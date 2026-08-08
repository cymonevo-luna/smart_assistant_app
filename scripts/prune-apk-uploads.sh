#!/usr/bin/env bash
# Prune old APK uploads on Nextcloud, keeping the newest N builds per folder.
#
# APK filenames are name-sortable (trailing UTC timestamp), so lexical order is
# chronological. Each app/build-type folder (<AppName>/debug|release/) is pruned
# independently.
#
# Usage:
#   scripts/prune-apk-uploads.sh [debug|release]   # default: debug
#
# Env (same as upload-apk-to-nextcloud.sh):
#   NEXTCLOUD_REMOTE, NEXTCLOUD_BASE_DIR, APP_NAME, RCLONE_CONFIG
#   APK_RETENTION_COUNT  number of newest APKs to keep (default: 2)
set -euo pipefail

log() { printf '>> %s\n' "$*" >&2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

BUILD_TYPE="${1:-debug}"
case "$BUILD_TYPE" in
	debug|release) ;;
	*)
		echo "ERROR: build type must be 'debug' or 'release' (got '$BUILD_TYPE')" >&2
		exit 2
		;;
esac

command -v rclone >/dev/null 2>&1 || {
	echo "ERROR: rclone not found on PATH." >&2
	exit 1
}

NEXTCLOUD_REMOTE="${NEXTCLOUD_REMOTE:-nextcloud}"
NEXTCLOUD_BASE_DIR="${NEXTCLOUD_BASE_DIR:-}"
KEEP="${APK_RETENTION_COUNT:-2}"
case "$KEEP" in
	''|*[!0-9]*)
		echo "ERROR: APK_RETENTION_COUNT must be a non-negative integer (got '$KEEP')" >&2
		exit 2
		;;
esac

read_pubspec() { grep -E "^$1:" "$REPO_DIR/pubspec.yaml" | head -n1 | sed -E "s/^$1:[[:space:]]*//" | tr -d '"'\'; }
if [ -z "${APP_NAME:-}" ]; then
	APP_NAME="$(read_pubspec name)"
fi
[ -n "$APP_NAME" ] || { echo "ERROR: could not resolve APP_NAME from pubspec.yaml" >&2; exit 1; }

REMOTE_FOLDER="${APP_NAME}/${BUILD_TYPE}"
if [ -n "$NEXTCLOUD_BASE_DIR" ]; then
	REMOTE_FOLDER="${NEXTCLOUD_BASE_DIR%/}/${REMOTE_FOLDER}"
fi
REMOTE_DIR="${NEXTCLOUD_REMOTE}:${REMOTE_FOLDER}"

# Filenames are mostly name-sortable, but legacy builds embed a git sha before the
# stamp (-debug-<sha>-YYYYMMDD-HHMMSS.apk). Extract the trailing UTC stamp for
# ordering so we always keep the chronologically newest builds.
apk_stamp_from_name() {
	local file="$1"
	if [[ "$file" =~ -([0-9]{8}-[0-9]{6})\.apk$ ]]; then
		printf '%s\n' "${BASH_REMATCH[1]}"
	else
		printf '%s\n' "$file"
	fi
}

mapfile -t APK_FILES < <(
	rclone lsf "$REMOTE_DIR" --files-only 2>/dev/null \
		| grep -E '\.apk$' \
		|| true
)

if [ "${#APK_FILES[@]}" -gt 1 ]; then
	mapfile -t APK_FILES < <(
		for file in "${APK_FILES[@]}"; do
			printf '%s\t%s\n' "$(apk_stamp_from_name "$file")" "$file"
		done | sort -k1,1 | cut -f2-
	)
fi

total="${#APK_FILES[@]}"
if [ "$total" -le "$KEEP" ]; then
	log "Prune skipped for ${REMOTE_FOLDER}: ${total} APK(s), keeping up to ${KEEP}"
	exit 0
fi

delete_count=$((total - KEEP))
log "Pruning ${REMOTE_FOLDER}: keeping ${KEEP} newest of ${total} APK(s), deleting ${delete_count}"

for ((i = 0; i < delete_count; i++)); do
	file="${APK_FILES[$i]}"
	target="${REMOTE_DIR}/${file}"
	log "Deleting old APK: ${REMOTE_FOLDER}/${file}"
	rclone deletefile "$target" >&2
done

log "Prune complete for ${REMOTE_FOLDER}"
