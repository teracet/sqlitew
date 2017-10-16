#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"

if [[ "$BUILD_OS" = "mac" ]] ; then
	ff_dist_bin_dir="$FF_DIST_DIR/SQLiteComposer.app/Contents/MacOS"
	ff_dist_res_dir="$FF_DIST_DIR/SQLiteComposer.app/Contents/Resources"
else
	ff_dist_bin_dir="$FF_DIST_DIR/bin"
	ff_dist_res_dir="$FF_DIST_DIR/bin"
fi


log "Configuring preferences"

mkdir -p "$ff_dist_res_dir/defaults/pref"
cp "$REPO_CONFIG_DIR/sqlite-composer.js" "$ff_dist_res_dir/defaults/pref"
cp "$REPO_CONFIG_DIR/mozilla.cfg" "$ff_dist_res_dir"


log "Removing extra binary"

rm -f "$ff_dist_bin_dir/sqlite-composer-bin-bin"


log "Installing SQLite Manager"

# When looking for where to install extensions so that they'd be packaged with
# the application, I found many "recommended" directories. However, I found the
# information to be outdated and unreliable. So instead, changes have been made
# to the installer to allow the "apps/" directory to be used.
# NOTE: If we decide to "properly" install extensions in the future, this is the
# best resource I've found:
# http://forums.mozillazine.org/viewtopic.php?p=11440295#p11440295

# Copy patched source.

sm_cp_dir="$ff_dist_res_dir/apps/sqlite-manager"
mkdir -p "$sm_cp_dir"
cp -R "$SM_SOURCE_DIR/"* "$sm_cp_dir"

# Patch version.

sedi "s/extVersion: \"x\.x\.x\"/extVersion: \"$SC_VERSION\"/" "$sm_cp_dir/chrome/resource/appInfo.js"


log "Installing launcher"

if [[ "$BUILD_OS" = "linux" ]] ; then
	cp "$REPO_CONFIG_DIR/linux-launcher.sh" "$ff_dist_bin_dir/sqlite-composer"
	cp "$REPO_CONFIG_DIR/linux-launcher.desktop" "$ff_dist_bin_dir/sqlite-composer.desktop"
fi

if [[ "$BUILD_OS" = "mac" ]] ; then
	cp "$REPO_CONFIG_DIR/mac-launcher.sh" "$ff_dist_bin_dir/sqlite-composer"
fi
