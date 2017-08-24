#!/bin/bash

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$REPO_DIR/build"
INSTALL_DIR="$BUILD_DIR/install"
APPS_DIR="$INSTALL_DIR/apps"


# RENAME FIREFOX BINARY

mv "$INSTALL_DIR/firefox" "$INSTALL_DIR/browser-bin"

# We can safely remove the duplicate binary.
rm -f $INSTALL_DIR/firefox-bin 


# CONFIGURE PREFERENCES

mkdir -p "$INSTALL_DIR/defaults/pref"
cp "$REPO_DIR/config/local-settings.js" "$INSTALL_DIR/defaults/pref"
cp "$REPO_DIR/config/mozilla.cfg" "$INSTALL_DIR"


# INSTALL SQLITE MANAGER

# Currently, there is only one extension: SQLite Manager. However, the
# installation is done in a way that allows multiple XUL apps to be installed
# simultaneously.

# NOTE: If we decide to "properly" install extensions in the future, see:
# http://forums.mozillazine.org/viewtopic.php?p=11440295#p11440295

# Copy the source.

EXT_DIR="$REPO_DIR/extensions/sqlite-manager-xr-0.8.3-all"
APP_DIR="$APPS_DIR/sqlite-manager"
rm -rf "$APP_DIR" && mkdir -p "$APP_DIR"
cp -r "$EXT_DIR/source/"* "$APP_DIR"

# Update the application.ini and other branding.

cp "$EXT_DIR/application.ini" "$APP_DIR"
grep -rl "SQLite Manager" "$APP_DIR" | xargs sed -i 's/SQLite Manager/SQLite Composer/g'

# Update the icons.

rm -f "$APP_DIR/chrome/icons/default/"*
cp "$EXT_DIR/icons/icon_16x16.png" "$APP_DIR/chrome/icons/default/default16.png"
cp "$EXT_DIR/icons/icon_32x32.png" "$APP_DIR/chrome/icons/default/default32.png"
cp "$EXT_DIR/icons/icon_128x128.png" "$APP_DIR/chrome/icons/default/default48.png" # TODO: Replace with real 48x48 icon
mkdir -p "$APP_DIR/icons"
cp "$EXT_DIR/icons/icon_128x128.png" "$APP_DIR/icons/mozicon128.png"

# Since we are not "properly" installing the extension, there is an unexpected
# exception that gets thrown; let's patch that.

sed -i 's/^.*SmAppInfo.extVersion =.*$/SmAppInfo.extVersion = (addon || {}).version || "xxx";/' "$APP_DIR/chrome/resource/appInfo.js"

# Copy the launcher files.

cp "$EXT_DIR/linux-launcher.sh" "$INSTALL_DIR/sqlite-composer"
cp "$EXT_DIR/linux-launcher.desktop" "$INSTALL_DIR/sqlite-composer.desktop"
