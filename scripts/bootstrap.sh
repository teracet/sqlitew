#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"


# Install tools needed to run bootstrap script

if [[ "$BUILD_OS" = "mac" ]] ; then
	# Part of the bootstrap process requires Xcode. If Xcode was installed
	# but not used yet, we need to specify the app directory.
	log 'Selecting Xcode app directory (requires sudo privileges)'
	sudo 'xcode-select' --switch '/Applications/Xcode.app' || error_exit "xcode-select failed"

	# Bootstrapping fails when installing rust on a Mac, so we will install
	# it manually ahead of time.
	log 'Installing rust'
	brew install rust || error_exit "failed to install rust"
fi


# Run bootstrap script

cd "$FF_SOURCE_DIR/python/mozboot/bin"
python bootstrap.py --application-choice=browser --no-interactive
