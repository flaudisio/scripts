#!/usr/bin/env bash

set -o pipefail

readonly SCRIPT_NAME="manage-audio"

SCRIPT_PATH="$( readlink --canonicalize "${BASH_SOURCE[0]}" )"
readonly SCRIPT_PATH
readonly SCRIPT_DIR="${SCRIPT_PATH%/*}"

CONFIG_FILE="$( readlink --canonicalize "${SCRIPT_DIR}/../conf/manage-audio.conf" )"
readonly CONFIG_FILE

# Device descriptions and port names differ per machine, so they come from a
# gitignored config file (`$CONFIG_FILE`); see `ls-ports` to build it.
if [[ -f "$CONFIG_FILE" ]] ; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

: "${DISABLED:=""}"

: "${SOURCE_DESCRIPTION:=""}"
: "${SINK_DESCRIPTION:=""}"

: "${HEADSET_SOURCE_PORT="[In] Headset"}"
: "${HEADSET_SINK_PORT="[Out] Headphones"}"
: "${SPEAKER_SINK_PORT="[Out] Speaker"}"
: "${INTERNAL_SOURCE_PORT="[In] Mic2"}"

: "${MIC_VOLUME:="28%"}"


function _msg()
{
    echo "$*" >&2
}

function _info()
{
    _msg "$*"
    notify-send --icon dialog-information --expire-time 2000 "$SCRIPT_NAME" "$*"
}

function _error()
{
    _msg "$*"
    notify-send --icon dialog-error --expire-time 2000 "$SCRIPT_NAME" "$*"
}

function get_pulse_audio_resource()
{
    local -r type="$1"
    local -r search="$2"

    if [[ -z "$search" ]] ; then
        _msg "Error: no description set for '$type'; configure it in $CONFIG_FILE"
        return 1
    fi

    if ! pactl --format json list "$type" \
        | jq -r --arg search "$search" '.[] | select(.description | contains($search))'
    then
        _msg "Error: could not get PulseAudio resource '$type'"
        return 1
    fi
}

# Print the device descriptions and their ports in config file syntax, so the
# output can be pasted into `$CONFIG_FILE`.
function print_device_config()
{
    local -r key="$1"
    local -r type="$2"
    local -r search="$3"

    pactl --format json list "$type" \
        | jq -r --arg key "$key" --arg search "$search" '
            .[]
            | select($search == "" or (.description | contains($search)))
            | "\($key)=\"\(.description)\"",
              ( .ports[]? | "# \(.name)" )'
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
        _info "Script is disabled, ignoring."
        exit 0
    fi

    case "$1" in
        ls-ports)
            echo "# Values for $CONFIG_FILE; uncomment the port lines you need."
            echo
            print_device_config "SOURCE_DESCRIPTION" "sources" "$SOURCE_DESCRIPTION"
            echo
            print_device_config "SINK_DESCRIPTION" "sinks" "$SINK_DESCRIPTION"
        ;;
        use-headset)
            if ! set_source_port "$SOURCE_DESCRIPTION" "$HEADSET_SOURCE_PORT" "$MIC_VOLUME" ; then
                _error "Error selecting headset mic. Run script in console for details."
                exit 1
            fi

            if ! set_sink_port "$SINK_DESCRIPTION" "$HEADSET_SINK_PORT" ; then
                _error "Error selecting headphones. Run script in console for details."
                exit 1
            fi

            # _info "Using headset"
        ;;
        use-speakers)
            if ! set_sink_port "$SINK_DESCRIPTION" "$SPEAKER_SINK_PORT" ; then
                _error "Error selecting speakers. Run script in console for details."
                exit 1
            fi

            # _info "Using speakers"
        ;;
        use-internal-mic)
            if ! set_source_port "$SOURCE_DESCRIPTION" "$INTERNAL_SOURCE_PORT" ; then
                _error "Error selecting internal mic. Run script in console for details."
                exit 1
            fi

            # _info "Using internal mic"
        ;;
        *)
            echo "Usage: $0 <ls-ports|use-headset|use-speakers|use-internal-mic>" >&2
            echo "Config: $CONFIG_FILE" >&2
            exit 2
        ;;
    esac
}

main "$@"
