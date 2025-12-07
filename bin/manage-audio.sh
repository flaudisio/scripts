#!/usr/bin/env bash

set -o pipefail

readonly ScriptName="manage-audio"

: "${DISABLED:=""}"

: "${HEADSET_SOURCE_PORT="[In] Headset"}"
: "${HEADSET_SINK_PORT="[Out] Headphones"}"

: "${MIC_VOLUME:="28%"}"


function _msg()
{
    echo -e "$*" >&2
}

function show_info()
{
    _msg "$*"
    notify-send --icon info --expire-time 2000 "$ScriptName" "$*"
}

function show_error()
{
    _msg "$*"
    notify-send --icon error --expire-time 2000 "$ScriptName" "$*"
}

function get_pulse_audio_resource()
{
    local -r type="$1"
    local -r search="$2"

    if ! pactl --format json list "$type" \
        | jq -r --arg search "$search" '.[] | select(.description | contains($search))'
    then
        _msg "Error: could not get PulseAudio resource '$type'"
        return 1
    fi
}

function set_sink_port()
{
    local -r description="$1"
    local -r port_name="$2"
    local sink_name

    if ! sink_name="$( get_pulse_audio_resource "sinks" "$description" | jq -r '.name' )" ; then
        return 1
    fi

    pactl set-sink-port "$sink_name" "$port_name" || return
    pactl set-default-sink "$sink_name" || return
}

function set_source_port()
{
    local -r description="$1"
    local -r port_name="$2"
    local -r volume="$3"
    local source_name

    if ! source_name="$( get_pulse_audio_resource "sources" "$description" | jq -r '.name' )" ; then
        return 1
    fi

    pactl set-source-port "$source_name" "$port_name" || return
    pactl set-default-source "$source_name" || return

    if [[ -n "$volume" ]] ; then
        pactl set-source-volume "$source_name" "$volume" || return
    fi
}

# NOTE: in Pulse Audio, audio input is 'source', while output is 'sink'
function main()
{
    if [[ -n "$DISABLED" ]] ; then
        show_info "Script is disabled, ignoring."
        exit 0
    fi

    # pactl list sources | egrep 'Name|Description'
    local source_description="Tiger Lake-LP Smart Sound Technology Audio Controller Headset Mono Microphone + Headphones Stereo Microphone"

    # pactl list sinks | egrep 'Name|Description'
    local sink_description="Tiger Lake-LP Smart Sound Technology Audio Controller Speaker + Headphones"

    case "$1" in
        ls-ports)
            echo "Input ports (sources):"
            get_pulse_audio_resource "sources" "$description" | jq -r '.ports[].name'
            echo
            echo "Output ports (sinks):"
            get_pulse_audio_resource "sinks" "$sink_description" | jq -r '.ports[].name'
        ;;
        use-headset)
            if ! set_source_port "$source_description" "$HEADSET_SOURCE_PORT" "$MIC_VOLUME" ; then
                show_error "Error selecting headset mic. Run script in console for details."
                exit 1
            fi

            if ! set_sink_port "$sink_description" "$HEADSET_SINK_PORT" ; then
                show_error "Error selecting headphones. Run script in console for details."
                exit 1
            fi

            show_info "Using headset"
        ;;
        use-speakers)
            if ! set_sink_port "$sink_description" "[Out] Speaker" ; then
                show_error "Error selecting speakers. Run script in console for details."
                exit 1
            fi

            show_info "Using speakers"
        ;;
        use-internal-mic)
            if ! set_source_port "$source_description" "[In] Mic2" ; then
                show_error "Error selecting internal mic. Run script in console for details."
                exit 1
            fi

            show_info "Using internal mic"
        ;;
        *)
            echo "Usage: $0 <ls-ports|use-headset|use-speakers|use-internal-mic>" >&2
            exit 2
        ;;
    esac
}

main "$@"
