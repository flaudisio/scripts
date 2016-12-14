#!/bin/bash

SpotifyService="org.mpris.MediaPlayer2.spotify"

show_error()
{
    zenity --error --text "$*"
}

get_spotify_pid()
{
    pgrep --oldest '^spotify$'
}

exec_spotify()
{
    spotify --minimized &> /dev/null &
}

start_spotify()
{
    local pid="$( get_spotify_pid )"
    local spotify_window_id

    if [[ -z "$pid" ]] ; then
        if ! command -v spotify &> /dev/null ; then
            show_error "Spotify não encontrado no sistema."
            exit 1
        elif ! exec_spotify ; then
            show_error "Erro ao iniciar Spotify."
            exit 1
        fi
    else
        spotify_window_id="$( wmctrl -l -p | grep "$pid" | awk '{ print $1 }' | head -n 1 )"

        # Maximiza Spotify
        wmctrl -i -a "$spotify_window_id"
    fi
}

if [[ -z "$1" ]] ; then
    show_error "Uso: $( basename "$0" ) {Start|PlayPause|Previous|Next|Stop}"
    exit 2
fi

case $1 in
    Start)
        start_spotify
    ;;

    PlayPause|Previous|Next|Stop)
        if ! get_spotify_pid ; then
            start_spotify
            sleep 2
        fi

        dbus-send \
            --print-reply \
            --dest="$SpotifyService" \
            /org/mpris/MediaPlayer2 \
            org.mpris.MediaPlayer2.Player.$1
    ;;

    *)
        show_error "Comando desconhecido: $1"
        exit 2
    ;;
esac
