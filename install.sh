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


##
## Entrada
##

[ -d "$DirTarget" ] || {
    echo "Criando diretório de destino: $DirTarget"
    mkdir -pv "$DirTarget"
    echo
}

echo "Criando links simbólicos de $DirSource/ para $DirTarget/..."
echo

ln -sv "$DirSource"/* "$DirTarget"

echo
echo "Feito."
