#!/usr/bin/env bash
set -euo pipefail

# Variables:
#   REPO_DIR              Absolute path to root of repo.
#   BUILD_OS              OS to build for (note that manually overriding this
#                          will not affect the Mozilla build system, and is
#                          untested; this variable is meant to provide
#                          convenient OS detection for scripts).
#   FF_SOURCE_DIR         Absolute path to directory where Firefox source will
#                          be downloaded to (default: $REPO_DIR/build/source)
#   FF_DIST_DIR           Absolute path to directory where Firefox build will be
#                          (default: $FF_SOURCE_DIR/obj-sqlite-composer/dist)
#   FF_VERSION            Firefox version (default: 54.0.1)
#   REPO_BUILD_DIR        (default: $REPO_DIR/build)
#   REPO_CONFIG_DIR       (default: $REPO_DIR/config)
#   REPO_ICON_DIR         (default: $REPO_DIR/icons)
#   REPO_NSIS_DIR         (default: $REPO_DIR/nsis)
#   REPO_SCRIPTS_DIR      (default: $REPO_DIR/scripts)
#   SC_VERSION            SQLite Composer version (default: 0.0.0)
#   SM_SOURCE_DIR         (default: $REPO_DIR/sqlite-manager)
#
# Functions:
#   log           Logs a message to the console
#   ask_yes_no    Prompts the user for a (y/n)
#   error_exit    Logs a message and exits
#   sedi          Provides uniform interface to `sed -i`, since the behaviour
#                  is different on Mac than it is on Linux


REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

BUILD_OS="${BUILD_OS:-`$REPO_SCRIPTS_DIR/detect-os.sh`}"
FF_SOURCE_DIR="${FF_SOURCE_DIR:-$REPO_DIR/build/source}"
FF_DIST_DIR="${FF_DIST_DIR:-$FF_SOURCE_DIR/obj-sqlite-composer/dist}"
FF_VERSION="${FF_VERSION:-54.0.1}"
REPO_BUILD_DIR="${REPO_BUILD_DIR:-$REPO_DIR/build}"
REPO_CONFIG_DIR="${REPO_CONFIG_DIR:-$REPO_DIR/config}"
REPO_ICON_DIR="${REPO_ICON_DIR:-$REPO_DIR/icons}"
REPO_NSIS_DIR="${REPO_NSIS_DIR:-$REPO_DIR/nsis}"
REPO_SCRIPTS_DIR="${REPO_SCRIPTS_DIR:-$REPO_DIR/scripts}"
SC_VERSION="${SC_VERSION:-0.0.0}"
SM_SOURCE_DIR="${SM_SOURCE_DIR:-$REPO_DIR/sqlite-manager}"

log () {
	echo "$(basename $0): $1"
}

ask_yes_no () {
	read -p "$(basename $0): $1" choice
	case "$choice" in
		y|Y) echo "yes" ;;
		n|N) echo "no" ;;
		*) echo "invalid" ;;
	esac
}

error_exit () {
	LOG "$1"
	exit "${2:-1}"
}

sedi () {
	sed --version >/dev/null 2>&1 && sed -i -- "$@" || sed -i "" "$@"
}
