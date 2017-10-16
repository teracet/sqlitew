#!/usr/bin/env bash
set -euo pipefail

# See:
#   https://stackoverflow.com/a/8597411/1422864
#   https://stackoverflow.com/a/18434831/1422864

case "$OSTYPE" in
	solaris*) echo "solaris" ;;
	darwin*)  echo "mac" ;;
	linux*)   echo "linux" ;;
	bsd*)     echo "bsd" ;;
	msys*)    echo "windows" ;;
	cygwin*)  echo "windows" ;;
	*)        echo "unknown" ;;
esac
