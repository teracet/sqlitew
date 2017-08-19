#!/bin/bash

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR=$REPO_DIR/build
INSTALL_DIR=$BUILD_DIR/install
APPS_DIR=$INSTALL_DIR/apps


# RENAME FIREFOX BINARY

mv $INSTALL_DIR/firefox $INSTALL_DIR/browser-bin

# We can safely remove the duplicate binary.
rm -f $INSTALL_DIR/firefox-bin 


# CONFIGURE PREFERENCES

mkdir -p $INSTALL_DIR/defaults/pref
cp $REPO_DIR/config/local-settings.js $INSTALL_DIR/defaults/pref
cp $REPO_DIR/config/mozilla.cfg $INSTALL_DIR


# INSTALL SQLITE MANAGER

# Currently, there is only one extension: SQLite Manager. However, the
# installation is done in a way that allows multiple XUL apps to be installed
# simultaneously.

# NOTE: If we decide to "properly" install extensions in the future, see:
# http://forums.mozillazine.org/viewtopic.php?p=11440295#p11440295

# Copy the source.

EXT_DIR=$REPO_DIR/extensions/sqlite-manager-xr-0.8.3-all
DEST_DIR=$APPS_DIR/sqlite-manager
rm -rf $DEST_DIR && mkdir -p $DEST_DIR
cp -r $EXT_DIR/source/* $DEST_DIR

# Update the application.ini, branding, and icons.

cp $EXT_DIR/application.ini $DEST_DIR
grep -rl "SQLite Manager" $DEST_DIR | xargs sed -i 's/SQLite Manager/SQLite Composer/g'
cp -r $INSTALL_DIR/browser/chrome/icons/* $DEST_DIR/icons

# Since we are not "properly" installing the extension, there is an unexpected
# exception that gets thrown; let's patch that.

sed -i 's/^.*SmAppInfo.extVersion =.*$/SmAppInfo.extVersion = (addon || {}).version || "xxx";/' $DEST_DIR/chrome/resource/appInfo.js

# Copy the launcher.

cp $EXT_DIR/linux-launcher.sh $INSTALL_DIR/sqlite-composer
