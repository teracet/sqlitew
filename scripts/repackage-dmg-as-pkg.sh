#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"

security unlock-keychain -p "$SIGNING_PASSWORD" "$HOME/Library/Keychains/login.keychain-db"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$SIGNING_PASSWORD" "$HOME/Library/Keychains/login.keychain-db"
security set-keychain-settings "$HOME/Library/Keychains/login.keychain-db"

hdiutil attach "$REPO_BUILD_DIR/SQLite Writer $SW_VERSION.dmg"
productbuild --sign "$SIGNING_IDENTITY_I" --component '/Volumes/SQLite Writer/SQLiteWriter.app' '/Applications' "$REPO_BUILD_DIR/SQLite Writer $SW_VERSION.pkg"
hdiutil detach '/Volumes/SQLite Writer'
