#!/usr/bin/env bash
#
# install.sh
#
# Symlink every script from bin/ into ~/.local/bin.
#
##

set -o pipefail
set -u

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" && pwd -P )"

readonly SCRIPT_DIR
readonly SOURCE_DIR="${SCRIPT_DIR}/bin"
readonly TARGET_DIR="${HOME}/.local/bin"

function _msg()
{
    echo "$*" >&2
}

function main()
{
    if [[ ! -d "$TARGET_DIR" ]] ; then
        _msg "--> Creating target directory '$TARGET_DIR'"

        mkdir --parents --verbose "$TARGET_DIR" || return
    fi

    _msg "--> Creating symbolic links from '$SOURCE_DIR' to '$TARGET_DIR'"

    ln --symbolic --verbose "$@" -- "$SOURCE_DIR"/* "$TARGET_DIR"
}

main "$@"
