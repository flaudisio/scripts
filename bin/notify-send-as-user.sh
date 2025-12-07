#!/usr/bin/env bash
# Inspired by: https://stackoverflow.com/a/49533938

[[ -n "$DEBUG" ]] && set -x

set -eo pipefail

function main()
{
    # List displays in use
    local -r socket_files=( /tmp/.X11-unix/X* )

    # Set the display name (e.g. ':0')
    local -r display=":$( basename "${socket_files[0]}" | tr -d 'X' )"

    # Find the user using such display
    local -r username="$( who | grep -F "(${display})" | awk '{ print $1 }' | head -n 1 )"

    # Get the user ID
    local -r uid="$( id -u "$username" )"

    sudo -H -u "$username" \
        DISPLAY="$display" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus" \
        notify-send "$@"
}

main "$@"
