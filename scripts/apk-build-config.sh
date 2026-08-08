#!/usr/bin/env bash
# Resolve APK build type (debug|release) for deploy/build scripts.
#
# Priority:
#   1. explicit CLI arg (debug|release)
#   2. APK_BUILD_TYPE env override
#   3. default: debug
#
# Jenkins picks the auto-deploy default per app from
# luna_jenkins/config/flutter-apk-build.conf and passes BUILD_TYPE into
# deploy-apk.sh as the first argument.
set -euo pipefail

resolve_apk_build_type() {
	local explicit="${1:-}"

	if [ -n "$explicit" ]; then
		case "$explicit" in
			debug|release)
				printf '%s\n' "$explicit"
				return 0
				;;
			*)
				echo "ERROR: build type must be 'debug' or 'release' (got '$explicit')" >&2
				return 2
				;;
		esac
	fi

	if [ -n "${APK_BUILD_TYPE:-}" ]; then
		case "$APK_BUILD_TYPE" in
			debug|release)
				printf '%s\n' "$APK_BUILD_TYPE"
				return 0
				;;
			*)
				echo "ERROR: APK_BUILD_TYPE must be 'debug' or 'release' (got '$APK_BUILD_TYPE')" >&2
				return 2
				;;
		esac
	fi

	printf '%s\n' "debug"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	resolve_apk_build_type "${1:-}"
fi
