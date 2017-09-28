#!/bin/bash

MAC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$MAC_DIR/.."
FIREFOX_VERSION=54.0.1
BUILD_DIR="$REPO_DIR/build"      # Directory where we can work
SOURCE_DIR="$BUILD_DIR/source"   # Destination for the firefox code
INSTALL_DIR="$SOURCE_DIR/obj-sqlite-composer/dist/bin"
APPS_DIR="$INSTALL_DIR/apps"
ICON_DIR="$REPO_DIR/extensions/sqlite-manager-xr-0.8.3-all/icons"


# DOWNLOAD SOURCE CODE

DOWNLOAD_URL="https://archive.mozilla.org/pub/firefox/releases/$FIREFOX_VERSION/source/firefox-$FIREFOX_VERSION.source.tar.xz"
FILE=firefox-source.tar.xz
#rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
#rm -rf "$SOURCE_DIR" && mkdir -p "$SOURCE_DIR"
#cd "$BUILD_DIR"
#curl -o "$FILE" "$DOWNLOAD_URL"
#tar -xf "$FILE" --directory "$SOURCE_DIR" --strip-components=1
#rm "$FILE"
unset DOWNLOAD_URL
unset FILE


# BOOTSTRAP

# Part of the bootstrap process requires Xcode. If Xcode was installed but not
# used yet, we need to specify the app directory.
echo 'Selecting Xcode app directory (requires sudo privileges).'
#sudo xcode-select --switch '/Applications/Xcode.app'

# Bootstrapping fails when installing rust on a Mac, so we will install it
# manually ahead of time.
echo 'Installing rust.'
#brew install rust

# In order to build Firefox, we need to install all of the libraries/tools it
# depends on.
# Fortunately, Firefox provides a convenient tool for us. Unfortunately, this
# tool is not well-suited to automation, so we need to force feed it some
# responses. Here is what each of the responses indicate:
#   Response #1: '2' - Build Firefox for Desktop
#   Response #2: '1' - Create shared state directory for mozilla tools
#   Response #3: '2' - Do not configure Mercurial

cd "$SOURCE_DIR"
#printf "2\n1\n2\n" | ./mach bootstrap


# PATCH: SQLITE FLAGS

# Firefox uses SQLite internally, and we need it compiled with the following
# flags:
#   SQLITE_ENABLE_JSON1
#   SQLITE_ENABLE_RTREE
# We can do that by editing the build file for SQLite before building Firefox.

echo 'DEFINES["SQLITE_ENABLE_JSON1"] = True' >> "$SOURCE_DIR/db/sqlite3/src/moz.build"
echo 'DEFINES["SQLITE_ENABLE_RTREE"] = True' >> "$SOURCE_DIR/db/sqlite3/src/moz.build"


# PATCH: BRANDING

BRANDING_DIR="$SOURCE_DIR/browser/branding/sqlite-composer"
cp -r "$SOURCE_DIR/browser/branding/unofficial" "$BRANDING_DIR"

# All of the changes in this section are to update any references to "Firefox"
# or "Mozilla" that will be spread when we compile.

sed -i '.original' 's/"Nightly"/"SQLite Composer"/'       "$BRANDING_DIR/locales/en-US/brand.dtd"
sed -i '.original' 's/=Nightly/=SQLite Composer/'         "$BRANDING_DIR/locales/en-US/brand.properties"
sed -i '.original' 's/"Mozilla"/"Teracet"/'               "$BRANDING_DIR/locales/en-US/brand.dtd"
sed -i '.original' 's/=Mozilla/=Teracet/'                 "$BRANDING_DIR/locales/en-US/brand.properties"
sed -i '.original' 's/Nightly/"SQLite Composer"/'         "$BRANDING_DIR/configure.sh"
echo 'MOZ_APP_NAME="sqlite-composer-bin"'              >> "$BRANDING_DIR/configure.sh"

cp "$ICON_DIR/mac/firefox.icns" "$BRANDING_DIR/firefox.icns"

unset BRANDING_DIR


# PATCH: VERSION

echo 'MOZ_APP_VERSION="0.0.1"' >> "$SOURCE_DIR/browser/branding/sqlite-composer/configure.sh"
echo '0.0.1' > "$SOURCE_DIR/browser/config/version.txt"
echo '0.0.1' > "$SOURCE_DIR/browser/config/version_display.txt"


# PATCH: INSTALLER

# Ensure our additional configuration files are included in the generated
# installer.

PACKAGE_MANIFEST="$SOURCE_DIR/browser/installer/package-manifest.in"
echo '[sqlite-composer]'                          >> "$PACKAGE_MANIFEST"
echo '@BINPATH@/apps/*'                           >> "$PACKAGE_MANIFEST"
echo '@RESPATH@/mozilla.cfg'                      >> "$PACKAGE_MANIFEST"
echo '@RESPATH@/defaults/pref/sqlite-composer.js' >> "$PACKAGE_MANIFEST"
unset PACKAGE_MANIFEST

# Patch the duplicate file error caused by including the sqlite-manager
# extension in the installer.

ALLOWED_DUPES="$SOURCE_DIR/browser/installer/allowed-dupes.mn"
echo 'apps/sqlite-manager/chrome/skin/default/images/close.gif' >> "$ALLOWED_DUPES"
echo 'chrome/toolkit/skin/classic/global/icons/Close.gif'       >> "$ALLOWED_DUPES"
unset ALLOWED_DUPES


# PATCH: DISABLED UPDATER BUG

# When building Firefox 54.0.1 with the updater disabled on a Mac, the build
# fails. This bug has been patched in later versions, and the fix can be found
# here:
# https://github.com/mozilla/gecko-dev/commit/5d98501bcf467c85def443ec6ad9c8b73a940cc3

# The sed commands look funky because the sed that is bundled with OS X is old,
# and "\n" is not supported within the replace string.

GUARD_OPEN='ifdef MOZ_UPDATER'
GUARD_CLOSE='endif'

sed -i '.original' "/mv -f/i\\
  $GUARD_OPEN\\
  " "$SOURCE_DIR/browser/app/Makefile.in"
sed -i '.original' "/ln -s/a\\
  $GUARD_CLOSE\\
  " "$SOURCE_DIR/browser/app/Makefile.in"

GUARD_OPEN='#ifdef MOZ_UPDATER'
GUARD_CLOSE='#endif'

sed -i '.original' "/LaunchServices/i\\
  $GUARD_OPEN\\
  " "$SOURCE_DIR/browser/installer/package-manifest.in"
sed -i '.original' "/LaunchServices/a\\
  $GUARD_CLOSE\\
  " "$SOURCE_DIR/browser/installer/package-manifest.in"

unset GUARD_OPEN
unset GUARD_CLOSE


# BUILD

cp "$REPO_DIR/config/mozconfig" mozconfig
read -p "About to configure..."
./mach configure
read -p "About to build..."
./mach build 2>&1 | tee "$BUILD_DIR/build.log"
read -p "Done building."


# CONFIGURE: PREFERENCES

mkdir -p "$INSTALL_DIR/defaults/pref"
cp "$REPO_DIR/config/sqlite-composer.js" "$INSTALL_DIR/defaults/pref"
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
grep -rl "SQLite Manager" "$APP_DIR" | xargs sed -i '.original' 's/SQLite Manager/SQLite Composer/g'

# Update the icons.

rm -f "$APP_DIR/chrome/icons/default/"*
cp "$EXT_DIR/icons/icon_16x16.png" "$APP_DIR/chrome/icons/default/default16.png"
cp "$EXT_DIR/icons/icon_32x32.png" "$APP_DIR/chrome/icons/default/default32.png"
cp "$EXT_DIR/icons/icon_48x48.png" "$APP_DIR/chrome/icons/default/default48.png"
mkdir -p "$APP_DIR/icons"
cp "$EXT_DIR/icons/icon_128x128.png" "$APP_DIR/icons/mozicon128.png"

# Since we are not "properly" installing the extension, there is an unexpected
# exception that gets thrown; let's patch that.
# We use "0.8.3" as the default version since that's the version that is saved
# in the repo; if we upgrade SQLite Manager, we should update this number as
# well.

sed -i '.original' 's/^.*SmAppInfo.extVersion =.*$/SmAppInfo.extVersion = (addon || {}).version || "0.8.3";/' "$APP_DIR/chrome/resource/appInfo.js"


# PACKAGE

read -p "About to build installer..."
./mach build installer
