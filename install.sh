#!/usr/bin/env bash
#
# install.sh
#
##

set -o pipefail

SOURCE_DIR="$( readlink -f "$( dirname "$0" )/bin" )"
TARGET_DIR="${HOME}/.local/bin"

LN_OPTS=( "$@" )

if [[ ! -d "$TARGET_DIR" ]] ; then
    echo "--> Creating target directory '$TARGET_DIR'"
    mkdir -pv "$TARGET_DIR"
fi

echo "--> Creating symbolic links from '$SOURCE_DIR' to '$TARGET_DIR'"

ln -s -v "${LN_OPTS[@]}" "$SOURCE_DIR"/* "$TARGET_DIR"

echo "--> Done"
