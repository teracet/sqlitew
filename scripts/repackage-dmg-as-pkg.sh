#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"

hdiutil attach "$REPO_BUILD_DIR/SQLite Writer $SW_VERSION.dmg"
pkgbuild --install-location '/Applications' --component '/Volumes/SQLite Writer/SQLiteWriter.app' "$REPO_BUILD_DIR/SQLite Writer $SW_VERSION.pkg"
hdiutil detach '/Volumes/SQLite Writer'
