#!/bin/bash
#
# delete-unused-packages.sh - Remove pacotes não utilizados
#
# Autor     : Flaudísio Tolentino
# Data      : Wed Nov 19 10:13:05 BRST 2014
#
##

[[ $( id -u ) -ne 0 ]] && sudo="sudo -H"

while true ; do
    echo "Procurando pacotes residuais..."

    PKGS=$(
        dpkg -l \
            | egrep '^rc' \
            | awk '{ print $2 }'
        deborphan
        deborphan --find-config
    )

    if [[ -n "$PKGS" ]] ; then
        echo -e "Removendo: $PKGS\n\n"

        $sudo aptitude purge $PKGS -P
    else
        echo "Nenhum pacote encontrado."
        break
    fi
done

exit $?
