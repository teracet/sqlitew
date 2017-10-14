#!/usr/bin/env bash

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/set-defaults.sh"

cd "$FF_SOURCE_DIR"

# In order to build Firefox, we need to install all of the libraries/tools it
# depends on.
# Fortunately, Firefox provides a convenient tool for us. Unfortunately, this
# tool is not well-suited to automation, so we need to force feed it some
# responses. These responses differ slightly from OS to OS.
# TODO: Not sure about other OSes, but at least on Mac, running mach bootstrap
# multiple times requires a different number of parameters.
case "$BUILD_OS" in
	linux)
		# Responses:
		#   2 - Build Firefox for Desktop
		#   3 - Do not install Mercurial
		#   1 - Create shared state directory for mozilla tools
		printf "2\n3\n1\n" | ./mach bootstrap
		;;

	mac)
		# Part of the bootstrap process requires Xcode. If Xcode was installed but not
		# used yet, we need to specify the app directory.
		echo 'Selecting Xcode app directory (requires sudo privileges).'
		sudo 'xcode-select' --switch '/Applications/Xcode.app'

		# Bootstrapping fails when installing rust on a Mac, so we will install it
		# manually ahead of time.
		echo 'Installing rust.'
		brew install rust

		# Responses:
		#   2 - Build Firefox for Desktop
		#   1 - Create shared state directory for mozilla tools
		#   2 - Do not configure Mercurial
		printf "2\n1\n2\n" | ./mach bootstrap
		;;

	windows)
		# Responses:
		#   2 - Build Firefox for Desktop
		#   1 - Create shared state directory for mozilla tools
		#   2 - Do not configure Mercurial
		printf "2\n1\n2\n" | ./mach bootstrap
		;;

	*)
		echo "Unrecognized or unsupported OS: $BUILD_OS"
		exit 1
		;;
esac
