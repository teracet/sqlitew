#!/usr/bin/env bash

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/set-defaults.sh"

cp "$REPO_CONFIG_DIR/mozconfig" "$FF_SOURCE_DIR/mozconfig"

cd "$FF_SOURCE_DIR"
./mach configure
./mach build 2>&1 | tee "$REPO_BUILD_DIR/build.log"
