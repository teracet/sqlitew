#!/bin/bash

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$REPO_DIR/build"      # Directory where we can work
SOURCE_DIR="$BUILD_DIR/source"   # Destination for the firefox code
INSTALL_DIR="$BUILD_DIR/install" # Destination for the built firefox
FIREFOX_VERSION=54.0.1
MOZCONFIG_PATH="$REPO_DIR/config/mozconfig"
NSIS_DIR="$SOURCE_DIR/browser/installer/windows/nsis"


# DOWNLOAD SOURCE CODE

DOWNLOAD_URL="https://archive.mozilla.org/pub/firefox/releases/$FIREFOX_VERSION/source/firefox-$FIREFOX_VERSION.source.tar.xz"
FILE=firefox-source.tar.xz
#rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
#rm -rf "$SOURCE_DIR" && mkdir -p "$SOURCE_DIR"
#cd "$BUILD_DIR"
#wget -O "$FILE" "$DOWNLOAD_URL"
#tar -xf "$FILE" --directory "$SOURCE_DIR" --strip-components=1
#rm "$FILE"
unset DOWNLOAD_URL
unset FILE


# BOOTSTRAP

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

# All of the changes in this section are to update any references to "Firefox"
# or "Mozilla" that will be spread when we compile. 

BRANDING_DIR="$SOURCE_DIR/browser/branding/sqlite-composer"
cp -r "$SOURCE_DIR/browser/branding/unofficial" "$BRANDING_DIR"

sed -i 's/"Nightly"/"SQLite Composer"/'                   "$BRANDING_DIR/locales/en-US/brand.dtd"
sed -i 's/=Nightly/=SQLite Composer/'                     "$BRANDING_DIR/locales/en-US/brand.properties"
sed -i 's/"Mozilla"/"Teracet"/'                           "$BRANDING_DIR/locales/en-US/brand.dtd"
sed -i 's/=Mozilla/=Teracet/'                             "$BRANDING_DIR/locales/en-US/brand.properties"
sed -i 's/"Mozilla Developer Preview"/"SQLite Composer"/' "$BRANDING_DIR/branding.nsi"
sed -i 's/"mozilla.org"/"teracet.com"/'                   "$BRANDING_DIR/branding.nsi"
sed -i 's/Nightly/"SQLite Composer"/'                     "$BRANDING_DIR/configure.sh"
echo 'MOZ_APP_NAME="sqlite-composer"' >>                  "$BRANDING_DIR/configure.sh"

unset BRANDING_DIR

sed -i 's/Mozilla Firefox/SQLite Composer/'                  "$NSIS_DIR/../app.tag"
sed -i 's/FirefoxMessageWindow/SQLiteComposerMessageWindow/' "$NSIS_DIR/defines.nsi.in"
sed -i 's/Firefox/SQLite Composer/'                          "$NSIS_DIR/defines.nsi.in"
sed -i 's/\Firefox/\${AppName}/'                             "$NSIS_DIR/installer.nsi"
sed -i 's/Mozilla\Firefox/Mozilla\${AppName}/'               "$NSIS_DIR/uninstaller.nsi"


# PATCH: INSTALLER

# This patch is to ensure our "apps/sqlite-manager" directory is included in
# the generated installer.

echo '[sqlite-composer]' >> "$SOURCE_DIR/browser/installer/package-manifest.in"
echo '@BINPATH@/apps/*' >> "$SOURCE_DIR/browser/installer/package-manifest.in"

# This patch adds a new shortcut within the installation directory so the user
# can start the application from there if necessary.

FILE="$NSIS_DIR/installer.nsi"
TMP_FILE="$NSIS_DIR/new-installer.nsi"
INSERT_BEFORE_LINE=$(grep -nF '${If} $AddDesktopSC == 1' "$FILE" | cut -d ':' -f 1)

{ head -n $(($INSERT_BEFORE_LINE-1)) "$FILE"; cat "$REPO_DIR/win-shortcut.nsi"; tail -n +$INSERT_BEFORE_LINE "$FILE"; } > "$TMP_FILE"
mv "$TMP_FILE" "$FILE"

unset FILE
unset TMP_FILE
unset INSERT_BEFORE_LINE

# This patches the various shortcuts that are created by the installer, since
# the browser-bin needs to be executed with particular arugments.

SC_PARAMS='"--app `\$INSTDIR\\apps\\sqlite-manager\\application.ini` --no-remote --profile `\$INSTDIR\\profiles\\sqlite-composer`"'
sed -i "/CreateShortCut/ s/\$/ $SC_PARAMS/" "$NSIS_DIR/installer.nsi"
unset SC_PARAMS


# CONFIGURE & BUILD

cp "$MOZCONFIG_PATH" mozconfig
./mach configure
./mach build


# INSTALL

# In order to extract the files that are required to run our newly built
# Firefox, we need to use the "install" rule from the makefile. But since we
# don't actually want to install it on this system, we made sure to configure
# the build to install into a temporary directory instead, where we can then
# take the necessary files.

#mkdir -p "$TMP_INSTALL_DIR"
#./mach install
#rm -rf "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR"
#mv "$TMP_INSTALL_DIR/lib/firefox-$FIREFOX_VERSION/"* "$INSTALL_DIR"
#rm -rf "$TMP_INSTALL_DIR"
#unset TMP_INSTALL_DIR
