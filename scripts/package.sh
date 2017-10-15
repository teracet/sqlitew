#!/usr/bin/env bash

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/set-defaults.sh"

case "$BUILD_OS" in
	linux)
		pkg_path="$REPO_BUILD_DIR/sqlite-composer-$SC_VERSION-linux.tar.gz"
		rm -f "$pkg_path"
		cd "$REPO_DIST_DIR"
		echo "NEEDS VERIFICATION" && exit 1
		tar -czf "$pkg_path" *
		;;
	mac)
		cd "$FF_SOURCE_DIR"
		./mach package | tee "$REPO_BUILD_DIR/package.log" || exit 1
		cp "$FF_DIST_DIR/sqlite-composer-bin-$SC_VERSION.en-US.mac.dmg" "$REPO_BUILD_DIR/sqlite-composer-$SC_VERSION.dmg"
		;;
	windows)
		cd "$FF_SOURCE_DIR"
		./mach build installer | tee "$REPO_BUILD_DIR/package.log" || exit 1
		;;
	*)
		echo "Unrecognized or unsupported OS: $BUILD_OS"
		exit 1
esac
