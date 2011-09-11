#!/bin/bash
#
# tlwn722n-linux-install: An automatic installer for Wireless USB device
# "TP-LINK TL-WN722N" or any other that uses the Atheros "htc_9271"
# firmware.
#
# Copyright (C) 2011 Erick Birbe <erickcion at gmail dot com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

CWPACKAGE="compat-wireless-2011-08-27"
CWEXT=".tar.bz2"
CWSHA1TXT="sha1sum.txt"
CWURL="http://linuxwireless.org/download/compat-wireless-2.6/"
DRIVERNAME="ath9k_htc"
MODULENAME="htc_9271"
PWD=$( pwd )
SRC="source"

# TODO comprobar el exito o fracaso de la ejecuacion de los comandos
# TODO comprobar si la carpeta no esta descargada y/o descomprimida ya

# TODO comprobar que existe WGET antes de ejecutar
echo "Downloading package \"$CWPACKAGE\"..."
wget -v -c $CWURL$CWPACKAGE$CWEXT -O $CWPACKAGE$CWEXT

# TODO hacer la verificacion y descargar de nuevo si no coinciden
#echo "Downloading sha1 sum..."
#wget -nv -c $CWURL/$CWSHA1TXT -O $CWSHA1TXT

# TODO comprobar la existencia del comando TAR
echo "Uncompressing the package..."
mkdir $SRC
tar jxvf $PWD/$CWPACKAGE$CWEXT -C $SRC

CWSRC=$SRC/$(ls -1tr $SRC | tail -1)
echo "Changing to directory \"$CWSRC\"..."
cd $CWSRC

echo "Uncompressing the package..."
./scripts/driver-select $DRIVERNAME

# TODO comprobar la existencia del comando MAKE
echo "Compiling modules..."
make

echo "Unloading old modules..."
#make -C $CWPACKAGE unload

# Cargando el nuevo modulo para el firmware
echo "Loading new module..."
#modprobe $MODULENAME

echo "Restoring $CWPACKAGE..."
./scripts/driver-select restore

echo "Returning to directory \"$PWD\"..."
cd $PWD
