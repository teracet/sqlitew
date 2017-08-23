#!/bin/bash

APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Update the .desktop file icon
ICON_PATH="$APP_DIR/browser/icons/mozicon128.png"
sed -i -e "s|^Icon=$|Icon=$ICON_PATH|" "$APP_DIR/sqlite-composer.desktop"

# Launch the app
PROFILE_DIR="$APP_DIR/profiles/sqlite-composer"
mkdir -p "$PROFILE_DIR"
"$APP_DIR/browser-bin" --app "$APP_DIR/apps/sqlite-manager/application.ini" --no-remote --profile "$PROFILE_DIR"
