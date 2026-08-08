#!/usr/bin/env bash
# Deploy this Flutter app: build the Android .apk and upload it to Nextcloud.
#
# This is the single entry point the luna_jenkins deploy host invokes (after it
# checks out the requested ref and stages the per-app .env + rclone.conf). It is
# the Flutter analogue of the backend services' scripts/refresh-daemon.sh.
#
# Usage:
#   scripts/deploy-apk.sh [debug|release]   # default: debug (see apk-build-config.sh)
#
# Auto-deploy BUILD_TYPE defaults are configured in luna_jenkins/config/flutter-apk-build.conf
# and passed by Jenkins; manual runs default to debug unless APK_BUILD_TYPE is set.
#
# All build/upload env overrides (FLUTTER_BIN, NEXTCLOUD_REMOTE,
# NEXTCLOUD_BASE_DIR, APP_NAME, RCLONE_CONFIG, ...) are honored by the scripts
# this one calls.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
BUILD_TYPE="$("$SCRIPT_DIR/apk-build-config.sh" "${1:-}")"

echo ">> Deploying APK (build type: $BUILD_TYPE)" >&2

APK_PATH="$("$SCRIPT_DIR/build-apk.sh" "$BUILD_TYPE" | tail -n1)"
echo ">> Built artifact: $APK_PATH" >&2

"$SCRIPT_DIR/upload-apk-to-nextcloud.sh" "$APK_PATH" "$BUILD_TYPE"

echo ">> APK deploy finished ($BUILD_TYPE)." >&2
