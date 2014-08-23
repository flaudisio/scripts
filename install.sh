#!/bin/bash
#
# install.sh
# Instala os scripts no diretório ~/bin
#
# Autor     : Flaudísio Tolentino <flaudisio@flaudisio.com>
# Data      : Wed Aug  7 13:40:14 BRT 2013
# Licença   : GPLv2
#
##

##
## Configurações
##

DirSource="$( readlink -f "$( dirname "$0" )/bin" )"
DirTarget="${HOME}/bin"

LnOpts="$@"


##
## Entrada
##

if [ ! -d "$DirTarget" ] ; then
    echo -e "Criando diretório de destino: $DirTarget\n"
    mkdir -pv "$DirTarget"
    echo
fi

echo -e "Criando links simbólicos de $DirSource/ para $DirTarget/...\n"

ln -sv "$LnOpts" "$DirSource"/* "$DirTarget"

echo -e "\nFeito."
