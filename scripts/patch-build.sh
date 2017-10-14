#!/usr/bin/env bash

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/set-defaults.sh"

if [[ "$BUILD_OS" = "mac" ]] ; then
	ff_bundle_dir="$FF_DIST_DIR/SQLiteComposer.app"
	ff_bundle_bin_dir="$ff_bundle_dir/Contents/MacOS"
	ff_bundle_res_dir="$ff_bundle_dir/Contents/Resources"
fi

# `sed -i` behaves differently on Linux and Mac, so this function abstracts
# those differences.
sedi () {
	sed --version >/dev/null 2>&1 && sed -i -- "$@" || sed -i "" "$@"
}


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
	linux)   FF_EXT_DIR="$FF_DIST_DIR/bin/apps" ;;
	mac)     FF_EXT_DIR="$ff_bundle_res_dir/apps" ;;
	windows) FF_EXT_DIR="$FF_DIST_DIR/bin/apps" ;;
	*)
		echo "Unrecognized or unsupported OS: $BUILD_OS"
		exit 1
		;;
esac

# Copy the source.

app_dir="$APPS_DIR/sqlite-manager"
mkdir -p "$app_dir"
cp -r "$SM_SOURCE_DIR/"* "$app_dir"

# Update the branding.

cp "$REPO_CONFIG_DIR/application.ini" "$app_dir"
grep --null -rl "SQLite Manager" "$app_dir" | xargs -0 sedi 's/SQLite Manager/SQLite Composer/g'

rm -f "$app_dir/chrome/icons/default/"*
cp "$REPO_ICON_DIR/icon_16x16.png" "$app_dir/chrome/icons/default/default16.png"
cp "$REPO_ICON_DIR/icon_32x32.png" "$app_dir/chrome/icons/default/default32.png"
cp "$REPO_ICON_DIR/icon_48x48.png" "$app_dir/chrome/icons/default/default48.png"
mkdir -p "$app_dir/icons"
cp "$REPO_ICON_DIR/icon_128x128.png" "$app_dir/icons/mozicon128.png"

# Since we are not "properly" installing the extension, there is an unexpected
# exception that gets thrown; let's patch that.
# We use "0.8.3" as the default version since that's the version that is saved
# in the repo; if we upgrade SQLite Manager, we should update this number as
# well.

sedi 's/^.*SmAppInfo.extVersion =.*$/SmAppInfo.extVersion = (addon || {}).version || "0.8.3";/' "$app_dir/chrome/resource/appInfo.js"


# INSTALL LAUNCHER

if [[ "$BUILD_OS" = "linux" ]] ; then
	cp "$REPO_CONFIG_DIR/linux-launcher.sh" "$FF_DIST_DIR/bin/sqlite-composer"
	cp "$REPO_CONFIG_DIR/linux-launcher.desktop" "$FF_DIST_DIR/bin/sqlite-composer.desktop"
fi

if [[ "$BUILD_OS" = "mac" ]] ; then
	cp "$REPO_CONFIG_DIR/mac-launcher.sh" "$ff_bundle_bin_dir/sqlite-composer"
fi
