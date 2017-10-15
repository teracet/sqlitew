#!/usr/bin/env bash

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/set-defaults.sh"

if [[ "$BUILD_OS" = "mac" ]] ; then
	ff_bundle_dir="$FF_DIST_DIR/SQLiteComposer.app"
	ff_bundle_bin_dir="$ff_bundle_dir/Contents/MacOS"
	ff_bundle_res_dir="$ff_bundle_dir/Contents/Resources"
fi


# CONFIGURE PREFERENCES

mkdir -p "$ff_bundle_res_dir/defaults/pref"
cp "$REPO_CONFIG_DIR/sqlite-composer.js" "$ff_bundle_res_dir/defaults/pref"
cp "$REPO_CONFIG_DIR/mozilla.cfg" "$ff_bundle_res_dir"


# INSTALL SQLITE MANAGER

# When looking for where to install extensions so that they'd be packaged with
# the application, I found many "recommended" directories. However, I found the
# information to be outdated and unreliable. So instead, changes have been made
# to the installer to allow the "apps/" directory to be used.
# NOTE: If we decide to "properly" install extensions in the future, this is the
# best resource I've found:
# http://forums.mozillazine.org/viewtopic.php?p=11440295#p11440295

case "$BUILD_OS" in
	linux)   ff_ext_dir="$FF_DIST_DIR/bin/apps" ;;
	mac)     ff_ext_dir="$ff_bundle_res_dir/apps" ;;
	windows) ff_ext_dir="$FF_DIST_DIR/bin/apps" ;;
	*)
		echo "Unrecognized or unsupported OS: $BUILD_OS"
		exit 1
		;;
esac

# Copy the source.

sm_cp_dir="$ff_ext_dir/sqlite-manager"
mkdir -p "$sm_cp_dir"
cp -r "$SM_SOURCE_DIR/"* "$sm_cp_dir"

# Patch the copy.

"$REPO_SCRIPTS_DIR/patch-sqlite-manager.sh" "$sm_cp_dir"


# INSTALL LAUNCHER

if [[ "$BUILD_OS" = "linux" ]] ; then
	cp "$REPO_CONFIG_DIR/linux-launcher.sh" "$FF_DIST_DIR/bin/sqlite-composer"
	cp "$REPO_CONFIG_DIR/linux-launcher.desktop" "$FF_DIST_DIR/bin/sqlite-composer.desktop"
fi

if [[ "$BUILD_OS" = "mac" ]] ; then
	cp "$REPO_CONFIG_DIR/mac-launcher.sh" "$ff_bundle_bin_dir/sqlite-composer"
fi
