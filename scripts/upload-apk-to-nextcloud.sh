#!/usr/bin/env bash
# Upload a built .apk to the shared luna Nextcloud using rclone (WebDAV).
#
# Layout on Nextcloud (under the configured base dir):
#   <base>/<AppName>/
#     debug/     <- development APKs (auto-deploy on master push)
#     release/   <- release APKs (manual, chosen via the Jenkins dropdown)
#
# rclone auto-creates the <AppName>/<debug|release>/ folders if missing.
#
# Usage:
#   scripts/upload-apk-to-nextcloud.sh <apk_path> [debug|release]   # default: debug
#
# Env:
#   NEXTCLOUD_REMOTE     rclone remote name (default: nextcloud). A WebDAV remote
#                        (vendor = nextcloud) whose URL points at the account's
#                        files root, e.g. https://cloud.example.com/remote.php/dav/files/USER
#   NEXTCLOUD_BASE_DIR   path prefix under the remote root that holds every app
#                        folder (default: empty = the remote root itself)
#   APP_NAME             override the app folder name (default: pubspec `name`)
#   RCLONE_CONFIG        path to an rclone.conf (the deploy host stages this)
#   APK_RETENTION_COUNT  newest APKs to keep per build-type folder (default: 2)
set -euo pipefail

log() { printf '>> %s\n' "$*" >&2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

APK_PATH="${1:?usage: upload-apk-to-nextcloud.sh <apk_path> [debug|release]}"
BUILD_TYPE="${2:-debug}"
case "$BUILD_TYPE" in
	debug|release) ;;
	*) echo "ERROR: build type must be 'debug' or 'release' (got '$BUILD_TYPE')" >&2; exit 2 ;;
esac
[ -f "$APK_PATH" ] || { echo "ERROR: APK not found: $APK_PATH" >&2; exit 1; }

command -v rclone >/dev/null 2>&1 || {
	echo "ERROR: rclone not found on PATH. Install rclone and configure the '${NEXTCLOUD_REMOTE:-nextcloud}' WebDAV remote." >&2
	exit 1
}

NEXTCLOUD_REMOTE="${NEXTCLOUD_REMOTE:-nextcloud}"
# Optional path prefix under the remote root that holds every app's folder.
# Empty uploads straight under the remote root.
NEXTCLOUD_BASE_DIR="${NEXTCLOUD_BASE_DIR:-}"

# Pull app name + version straight out of pubspec.yaml (no yq dependency).
read_pubspec() { grep -E "^$1:" pubspec.yaml | head -n1 | sed -E "s/^$1:[[:space:]]*//" | tr -d '"'\'; }
APP_NAME="${APP_NAME:-$(read_pubspec name)}"
VERSION="$(read_pubspec version)"
[ -n "$APP_NAME" ] || { echo "ERROR: could not resolve APP_NAME from pubspec.yaml" >&2; exit 1; }
[ -n "$VERSION" ] || VERSION="0.0.0"

STAMP="$(date -u +%Y%m%d-%H%M%S)"
# e.g. my_app-v1.0.0+1-debug-20260621-120000.apk
# Name-sortable by design: the constant prefix is followed by a trailing UTC
# timestamp, so lexical order matches build order and the newest build sorts
# last by name. Mobile/web Nextcloud clients only sort by name, so no git sha is
# embedded — it would break that ordering (and the commit is already in the log).
FILENAME="${APP_NAME}-v${VERSION}-${BUILD_TYPE}-${STAMP}.apk"

# Destination path under the remote, trimming any stray slash on the base dir.
REMOTE_PATH="${APP_NAME}/${BUILD_TYPE}/${FILENAME}"
if [ -n "$NEXTCLOUD_BASE_DIR" ]; then
	REMOTE_PATH="${NEXTCLOUD_BASE_DIR%/}/${REMOTE_PATH}"
fi
DEST="${NEXTCLOUD_REMOTE}:${REMOTE_PATH}"

log "Uploading $BUILD_TYPE APK to Nextcloud: ${REMOTE_PATH}"
# copyto writes to the exact path and creates parent dirs as needed. --no-traverse
# avoids listing the destination tree for a single-file copy.
rclone copyto "$APK_PATH" "$DEST" --no-traverse >&2

log "Upload complete: ${REMOTE_PATH}"

if [ "${APK_PRUNE_AFTER_UPLOAD:-1}" = "1" ]; then
	"$SCRIPT_DIR/prune-apk-uploads.sh" "$BUILD_TYPE"
fi

printf '%s\n' "${REMOTE_PATH}"
