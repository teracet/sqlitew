#!/usr/bin/env bash

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/set-defaults.sh"

download_url="https://archive.mozilla.org/pub/firefox/releases/$FF_VERSION/source/firefox-$FF_VERSION.source.tar.xz"
file=firefox-source.tar.xz

mkdir -p "$FF_SOURCE_DIR"
cd "$REPO_BUILD_DIR"

echo "Downloading Firefox source..."
curl -o "$file" "$download_url"
echo "Downloaded Firefox source."

echo "Unpacking Firefox source..."
tar -xf "$file" --directory "$FF_SOURCE_DIR" --strip-components=1
echo "Unpacked Firefox source."

rm "$file"
