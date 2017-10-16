#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"

cd "$FF_SOURCE_DIR"
./mach configure || error_exit "mach configure failed"
./mach build 2>&1 | tee "$REPO_BUILD_DIR/build.log"
