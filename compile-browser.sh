#!/bin/bash

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$REPO_DIR/build"      # Directory where we can work
SOURCE_DIR="$BUILD_DIR/source"   # Destination for the firefox code
INSTALL_DIR="$BUILD_DIR/install" # Destination for the built firefox
FIREFOX_VERSION=54.0.1
MOZCONFIG_PATH="$REPO_DIR/config/mozconfig"


# DOWNLOAD SOURCE CODE

DOWNLOAD_URL="https://archive.mozilla.org/pub/firefox/releases/$FIREFOX_VERSION/source/firefox-$FIREFOX_VERSION.source.tar.xz"
FILE=firefox-source.tar.xz
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
rm -rf "$SOURCE_DIR" && mkdir -p "$SOURCE_DIR"
cd "$BUILD_DIR"
wget -O "$FILE" "$DOWNLOAD_URL"
tar -xf "$FILE" --directory "$SOURCE_DIR" --strip-components=1
rm "$FILE"
unset DOWNLOAD_URL
unset FILE


# BOOTSTRAP

# In order to build Firefox, we need to install all of the libraries/tools it
# depends on.
# Fortunately, Firefox provides a convenient tool for us. Unfortunately, this
# tool is not well-suited to automation, so we need to force feed it some
# responses. Here is what each of the responses indicate:
#   Response #1: '2' - Build Firefox for Desktop
#   Response #2: '3' - Do not install Mercurial
#   Response #3: '1' - Create a build directory (this needs more explanation)

cd "$SOURCE_DIR"
printf "2\n3\n1\n" | ./mach bootstrap


# SQLITE FLAGS

# Firefox uses SQLite internally, and we need it compiled with the following
# flags:
#   SQLITE_ENABLE_JSON1
#   SQLITE_ENABLE_RTREE
# We can do that by editing the build file for SQLite before building Firefox.

LINE='DEFINES["SQLITE_ENABLE_JSON1"] = True'
FILE=db/sqlite3/src/moz.build
grep -qF "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

# We use grep to make sure that the line doesn't already exist.

LINE='DEFINES["SQLITE_ENABLE_RTREE"] = True'
FILE=db/sqlite3/src/moz.build
grep -qF "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

unset LINE
unset FILE


# CONFIGURE & BUILD

# The temporary install directory will be explained in the next step.

TMP_INSTALL_DIR="$BUILD_DIR/tmp-install"
cp "$MOZCONFIG_PATH" mozconfig
./mach configure --prefix="$TMP_INSTALL_DIR"
./mach build


# INSTALL

# In order to extract the files that are required to run our newly built
# Firefox, we need to use the "install" rule from the makefile. But since we
# don't actually want to install it on this system, we made sure to configure
# the build to install into a temporary directory instead, where we can then
# take the necessary files.

mkdir -p "$TMP_INSTALL_DIR"
./mach install
rm -rf "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR"
mv "$TMP_INSTALL_DIR/lib/firefox-$FIREFOX_VERSION/"* "$INSTALL_DIR"
rm -rf "$TMP_INSTALL_DIR"
unset TMP_INSTALL_DIR
