#!/usr/bin/env bash
set -euo pipefail

if [ -z "$1" ] ; then
	echo "Usage: $0 /path/to/sqlite-manager"
	exit 1
fi

SM_SOURCE_DIR="$1"
REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"


log "Patching branding"

cp "$REPO_CONFIG_DIR/application.ini" "$SM_SOURCE_DIR"
grep -rl "SQLite Manager" "$SM_SOURCE_DIR" | while read -r file ; do
	sedi 's/SQLite Manager/SQLite Composer/g' "$file"
done

rm -f "$SM_SOURCE_DIR/chrome/icons/default/"*
cp "$REPO_ICON_DIR/icon_16x16.png" "$SM_SOURCE_DIR/chrome/icons/default/default16.png"
cp "$REPO_ICON_DIR/icon_32x32.png" "$SM_SOURCE_DIR/chrome/icons/default/default32.png"
cp "$REPO_ICON_DIR/icon_48x48.png" "$SM_SOURCE_DIR/chrome/icons/default/default48.png"
mkdir -p "$SM_SOURCE_DIR/icons"
cp "$REPO_ICON_DIR/icon_128x128.png" "$SM_SOURCE_DIR/icons/mozicon128.png"


log "Patching version"

# Since we are not "properly" installing the extension, there is an unexpected
# exception that gets thrown; let's patch that.
# We use "0.8.3" as the default version since that's the version that is saved
# in the repo; if we upgrade SQLite Manager, we should update this number as
# well.

sedi 's/^.*SmAppInfo.extVersion =.*$/SmAppInfo.extVersion = (addon || {}).version || "0.8.3";/' "$SM_SOURCE_DIR/chrome/resource/appInfo.js"
