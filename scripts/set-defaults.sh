#!/usr/bin/env bash

# Variables:
#   BUILD_OS - The OS to build for (note that manually overriding this will not
#              affect the Mozilla build system, and is untested; this variable
#              is meant to provide easy OS detection for scripts).
#   FF_SOURCE_DIR - Absolute path to directory where Firefox source will be
#                   downloaded to (default: $REPO/build/source)
#   FF_VERSION - Firefox version to download (default: 54.0.1)
#   REPO_SCRIPTS_DIR - Absolute path to directory where repo scripts are kept
#                      (default: $REPO/scripts)

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
