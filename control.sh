#!/usr/bin/env bash

# To see what variables can be configured, see `scripts/set-defaults.sh`

export SC_VERSION=0.0.1

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_SCRIPTS_DIR="$REPO_DIR/scripts"
. "$REPO_SCRIPTS_DIR/set-defaults.sh"

log () {
	echo "$0: $1"
}

ask_yes_no () {
	read -p "$0: $1" choice
	case "$choice" in
		y|Y) echo "yes" ;;
		n|N) echo "no" ;;
		*) echo "invalid" ;;
	esac
}

case "$1" in
	setup)
		log "Setup started."

		if [ ! -d "$FF_SOURCE_DIR" ] ; then
			download=$(ask_yes_no "The Firefox source is required for setup. Download now (y/n)? ")

			if [ "$download" = "yes" ] ; then
				log "Downloading now..."
				"$REPO_SCRIPTS_DIR/download.sh"
				log "Firefox source downloaded."
			else
				log "Setup aborted."
				exit 1
			fi
		fi

		log "Running bootstrap..."
		"$REPO_SCRIPTS_DIR/bootstrap.sh"
		log "Bootstrap finished."

		log "Setup was successful."
		;;

	build)
		log "Build started."

		if [ ! -d "$FF_SOURCE_DIR" ] ; then
			download=$(ask_yes_no "Firefox source is missing. Download now (y/n)? ")

			if [ "$download" = "yes" ] ; then
				log "Downloading now..."
				"$REPO_SCRIPTS_DIR/download.sh"
				log "Firefox source downloaded."
			else
				log "Build aborted."
				exit 1
			fi
		fi

		log "Patching Firefox source..."
		"$REPO_SCRIPTS_DIR/patch-source.sh"
		log "Patched Firefox source."

		log "Compiling Firefox source... (this will take awhile)"
		"$REPO_SCRIPTS_DIR/compile.sh"
		log "Compiled Firefox source."

		log "Patching Firefox build..."
		"$REPO_SCRIPTS_DIR/patch-build.sh"
		log "Patched Firefox build."

		log "Build was successful."
		;;

	package)
		log "Packaging started."
		"$REPO_SCRIPTS_DIR/package.sh"
		log "Packaging was successful; see build/ directory."
		;;

	*)
		cat >&2 <<EOF
Usage: $0 command
Commands:
  setup         Install packages needed to build Firefox.
  build         Download, patch, compile, and configure Firefox as SQLite
                Composer.
  package       Package the app either as an installer (Mac/Windows) or as a
                tarball (Linux).
EOF
		exit 1
		;;
esac
