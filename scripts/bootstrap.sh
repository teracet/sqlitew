#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"

cd "$FF_SOURCE_DIR/python/mozboot/bin"
python bootstrap.py --application-choice=browser --no-interactive
