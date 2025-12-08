#!/usr/bin/env bash
#
# rp-pruner.sh
#
# Helper script to prune paths from restic repositories, powered by resticprofile.
#
##

[[ -n "$DEBUG" ]] && set -x

set -e
set -o pipefail

RP_CMD=( resticprofile )

function _msg()
{
    echo "$*" >&2
}

function _run()
{
    echo "+ $*" >&2
    "$@"
}

function _confirm()
{
    local -r prompt="$1"
    local option

    read -r -p "$prompt (y/N) " option

    [[ "$option" =~ ^[yY]$ ]]
}

function rewrite_snapshots()
{
    local paths_to_remove=( "$@" )
    local snapshot_ids=()

    _msg "Searching for snapshots containing paths ${paths_to_remove[*]}"

    mapfile -t snapshot_ids < <(
        _run "${RP_CMD[@]}" --quiet find --json "${paths_to_remove[@]}" | jq -r '.[].snapshot'
    )

    if [[ -z "${snapshot_ids[0]}" ]] ; then
        _msg "No snapshots found"
        return 0
    fi

    _msg "Found ${#snapshot_ids[@]} snapshot(s) to rewrite:"

    echo "${snapshot_ids[@]}" | tr ' ' '\n' >&2

    _confirm "Rewrite snapshots?" || return 0

    local exclude_args=()
    local path

    for path in "${paths_to_remove[@]}" ; do
        exclude_args+=( --exclude "$path" )
    done

    _msg "Rewriting snapshots"

    _run "${RP_CMD[@]}" rewrite "${exclude_args[@]}" "${snapshot_ids[@]}"

    _confirm "Forget snapshots?" || return 0

    _msg "Forgetting snapshots"

    _run "${RP_CMD[@]}" forget "${snapshot_ids[@]}"
}

function cleanup_snapshots()
{
    _confirm "Remove tag 'rewrite' from snapshots?" || return 0

    _msg "Removing tag 'rewrite' from snapshots"

    _run "${RP_CMD[@]}" tag --tag rewrite --remove rewrite
}

function main()
{
    if [[ $# -lt 2 ]] ; then
        _msg "Usage: $0 PROFILE_NAME PATH1 [PATH2]"
        exit 2
    fi

    RP_CMD+=( --name "$1" )
    shift
    local -r paths_to_remove=( "$@" )

    _msg "Starting at $( date )"

    rewrite_snapshots "${paths_to_remove[@]}"
    cleanup_snapshots

    _msg "Done!"
}

main "$@"
