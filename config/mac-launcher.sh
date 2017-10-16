#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$ROOT_DIR/../MacOS"
RES_DIR="$ROOT_DIR/../Resources"

# Noramlize the binary and resource directories.
# If you're questioning why this is necessary, try commenting these out and
# running the app; it'll crash and leave you with "Couldn't load XPCOM."
# While I'm not 100%, I suspect this is security related, and that macOS is
# blocking the dylibs from loading. After removing any ".." from the binary
# path, everything seems to be cool.
BIN_DIR="`cd \"$BIN_DIR\"; pwd`"
RES_DIR="`cd \"$RES_DIR\"; pwd`"

APP_DIR="$RES_DIR/apps/sqlite-manager"
PROFILE_DIR="$HOME/.teracet/sqlite-composer/profile"
mkdir -p "$PROFILE_DIR"
"$BIN_DIR/sqlite-composer-bin" --app "$APP_DIR/application.ini" --no-remote --profile "$PROFILE_DIR"
