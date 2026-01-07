#!/bin/bash
#
# Script based on https://github.com/jc00ke/move-to-next-monitor
#
# Move the current window to the next monitor.
#
# Also works only on one X screen (which is the most common case).
#
# Props to
# https://web.archive.org/web/20230307033958/http://icyrock.com/blog/2012/05/xubuntu-moving-windows-between-monitors/
#
# Unfortunately, both "xdotool getwindowgeometry --shell $window_id" and
# checking "-geometry" of "xwininfo -id $window_id" are not sufficient, as
# the first command does not respect panel/decoration offsets and the second
# will sometimes give a "-0-0" geometry. This is why we resort to "xwininfo".

function get_new_window_positions()
{
    local -r display_geometry="$( xdotool getdisplaygeometry )"
    local -r display_width="$( cut -d ' ' -f 1 <<< "$display_geometry" )"
    local -r display_height="$( cut -d ' ' -f 2 <<< "$display_geometry" )"

    local -r window_info="$( xwininfo -id "$window_id" )"

    # Read window position
    local -r current_x="$( awk '/Absolute upper-left X:/ { print $4 }' <<< "$window_info" )"
    local -r current_y="$( awk '/Absolute upper-left Y:/ { print $4 }' <<< "$window_info" )"

    # Read any offsets caused by panels or window decorations
    local -r x_offset="$( awk '/Relative upper-left X:/ { print $4 }' <<< "$window_info" )"
    local -r y_offset="$( awk '/Relative upper-left Y:/ { print $4 }' <<< "$window_info" )"

    # Subtract the offsets
    local -r fixed_x="$(( current_x - x_offset ))"
    local -r fixed_y="$(( current_y - y_offset ))"

    # Compute the final X and Y positions
    local -r new_x="$(( fixed_x + display_width ))"
    local -r new_y="$(( fixed_y + display_height ))"

    echo "${new_x}:${new_y}"
}

function get_adjusted_window_positions()
{
    local -r window_id="$1"
    local x_pos="$2"
    local y_pos="$3"

    local -r screen_dimensions="$( xdpyinfo | awk '/dimensions:/ { print $2 }' )"
    local -r screen_width="$( cut -d 'x' -f 1 <<< "$screen_dimensions" )"
    local -r screen_height="$( cut -d 'x' -f 2 <<< "$screen_dimensions" )"

    local -r window_geometry="$( xdotool getwindowgeometry "$window_id" | awk '/Geometry:/ { print $2 }' )"
    local -r window_width="$( cut -d 'x' -f 1 <<< "$window_geometry" )"
    local -r window_height="$( cut -d 'x' -f 2 <<< "$window_geometry" )"

    # If we would move off the right-most monitor, we set it to the left one
    # We also respect the window's width and height here: moving a window off more than half its width won't happen
    if [[ $(( x_pos + window_width / 2 )) -gt $screen_width ]] ; then
        x_pos="$(( x_pos - screen_width ))"
    fi

    if [[ $(( y_pos + window_height / 2 )) -gt $screen_height ]] ; then
        y_pos="$(( y_pos - screen_height ))"
    fi

    # Don't move off the left side
    [[ $x_pos -lt 0 ]] && x_pos=0

    # Don't move off the bottom
    [[ $y_pos -lt 0 ]] && y_pos=0

    echo "${x_pos}:${y_pos}"
}

function restore_window_size()
{
    local -r window_id="$1"
    local -r window_state="$2"

    local wmctrl_opts="add"

    # Append options to re-maximize the window according to its original state
    grep -q '_NET_WM_STATE_MAXIMIZED_VERT' <<< "$window_state" && wmctrl_opts="${wmctrl_opts},maximized_vert"
    grep -q '_NET_WM_STATE_MAXIMIZED_HORZ' <<< "$window_state" && wmctrl_opts="${wmctrl_opts},maximized_horz"

    # Restore the window size
    wmctrl -i -r "$window_id" -b "$wmctrl_opts"
}

function main()
{
    local -r window_id="$( xdotool getactivewindow )"

    # Do not move the desktop window
    # Ref: https://github.com/jc00ke/move-to-next-monitor/pull/12
    if xprop -id "$window_id" WM_CLASS | grep -q '"Xfdesktop"' ; then
        exit 0
    fi

    # Remember the current window state before un-maximizing it
    local -r window_state="$( xprop -id "$window_id" _NET_WM_STATE )"

    # Un-maximize the window so we can move it
    wmctrl -i -r "$window_id" -b remove,maximized_vert,maximized_horz

    # Get new window coordinates
    local -r new_win_pos="$( get_new_window_positions "$window_id" )"
    local -r new_x="${new_win_pos%:*}"
    local -r new_y="${new_win_pos#*:}"

    # Get adjusted window coordinates
    local -r adjusted_win_pos="$( get_adjusted_window_positions "$window_id" "$new_x" "$new_y" )"
    local -r adjusted_x="${adjusted_win_pos%:*}"
    local -r adjusted_y="${adjusted_win_pos#*:}"

    # Move the window to the new coordinates
    xdotool windowmove "$window_id" "$adjusted_x" "$adjusted_y"

    # Finally, restore the window's original size
    restore_window_size "$window_id" "$window_state"
}

main "$@"
