#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/apps/sqlite-manager"

# Update the .desktop file icon
ICON_PATH="$APP_DIR/icons/mozicon128.png"
sed -i -e "s|^Icon=$|Icon=$ICON_PATH|" "$ROOT_DIR/sqlite-composer.desktop"

# Launch the app
PROFILE_DIR="$HOME/.teracet/sqlite-composer/profile"
mkdir -p "$PROFILE_DIR"
"$ROOT_DIR/sqlite-composer-bin" --app "$APP_DIR/application.ini" --no-remote --profile "$PROFILE_DIR"
