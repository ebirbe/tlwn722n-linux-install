#!/bin/bash
#
# tlwn722n-linux-install: An automatic installer for Wireless USB device
# "TP-LINK TL-WN722N" or any other that uses the Atheros "htc_9271"
# firmware.
#
# Copyright (C) 2011 Erick Birbe <erickcion@gmail.com>
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

CWPACKAGE="compat-wireless-2.6"
CWEXT=".tar.bz2"
CWURL="http://linuxwireless.org/download/compat-wireless-2.6/"
MOD_NAME="ath9k_htc"
FW_NAME="htc_9271.fw"
CWDRVSLCT="./scripts/driver-select"
FW_DIR="/lib/firmware/"
MOD_DIR="/lib/modules/"$(uname -r)
PWD=$( pwd )/
SRC="source"

# TODO descargar firmware
# TODO Comprobar y descargar linux-header

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ -d $MOD_DIR ]; then
	echo ""
else
	if [ -x "`which apt-get`" ]; then
		apt-get install linux-headers-$(uname -r)
		if [ $? -ne 0 ]; then
			echo "There was a problem installing your linux headers." 1>&2
			exit 1
		fi
	else
		echo "The linux headers can not be found nor installed." 1>&2
		exit 1
	fi
fi

if [ -f $PWD$CWPACKAGE$CWEXT ]; then
	# The file is present, Do not download and continue
	echo ""
else
	if [ -x "`which wget`" ]; then
		echo "Downloading package" $CWPACKAGE", please wait..."
		wget -v $CWURL$CWPACKAGE$CWEXT -O $CWPACKAGE$CWEXT
		if [ $? -ne 0 ]; then
			echo "There was a problem downloading" $CWPACKAGE 1>&2
			exit 1
		fi
	else
		echo "wget is not installed." 1>&2
		echo "Please, install wget to continue." 1>&2
		exit 1
	fi
fi

if [ -d $FW_DIR ]; then
	if [ -f $FW_DIR$FW_NAME ]; then
		echo ""
	else
		cp $PWD$FW_NAME $FW_DIR
		if [ $? -ne 0 ]; then
			echo "There was a problem copying" $PWD$FW_NAME "to" $FW_DIR 1>&2
			exit 1
		fi
	fi
else
	echo "Unable to find the directory" $FW_DIR 1>&2
	exit 1
fi

if [ -x "`which tar`" ]; then
	echo "Decompressing the package, please wait..."
	if [ -d $SRC ]; then
		echo ""
	else
		mkdir $SRC
	fi
	if [ $? -ne 0 ]; then
		echo "There was a problem creating the directory, check your permissions." 1>&2
		exit 1
	fi
	tar jxvf $PWD$CWPACKAGE$CWEXT -C $SRC
	if [ $? -ne 0 ]; then
		echo "There was a problem decompressing" $CWPACKAGE$CWEXT 1>&2
		exit 1
	fi
else
	echo "tar is not installed."
	echo "Please, install tar to continue."
	exit
fi

CWSRC=$SRC/$(ls -1tr $SRC | tail -1)
echo "Changing to directory \"$CWSRC\"..."
cd $CWSRC

echo "Trying to select the $MOD_NAME diver to be compiled..."
if [ -f $CWDRVSLCT ]; then
	if [ -x $CWDRVSLCT ]; then
		$CWDRVSLCT $MOD_NAME
		if [ $? -ne 0 ]; then
			echo "There was a problem selecting the driver. Will run the complete compilation." 1>&2
		fi
	else
		echo $CWDRVSLCT "is not executable." 1>&2
	fi
else
	echo $CWDRVSLCT "does not exists." 1>&2
fi

if [ -x "`which make`" ]; then
	echo "Compiling modules..."
	make
	if [ $? -ne 0 ]; then
		echo "There was a problem compiling the package." 1>&2
		exit 1
	fi
	echo "Installing new modules..."
	make install
	if [ $? -ne 0 ]; then
		echo "There was a problem installing the modules." 1>&2
		exit 1
	fi
	echo "Unloading old modules..."
	make unload
	if [ $? -ne 0 ]; then
		echo "There was a problem unloading old modules." 1>&2
		exit 1
	fi
else
	echo "make is not installed." 1>&2
	echo "Please, install make to continue." 1>&2
	exit
fi

# Cargando el nuevo modulo del firmware
if [ -x "`which modprobe`" ]; then
	echo "Loading new module..."
	modprobe $MOD_NAME
	if [ $? -ne 0 ]; then
		echo "There was a problem using modprobe." 1>&2
		echo "Try rebooting to apply the changes." 1>&2
		exit 1
	fi
else
	echo "Can not find modprobe," 1>&2
	echo "So please reboot to apply the changes." 1>&2
	exit
fi

echo "Restoring" $CWPACKAGE"..."
$CWDRVSLCT restore
if [ $? -ne 0 ]; then
	echo $CWPACKAGE "Could not be restored." 1>&2
fi

echo "Returning to directory" $PWD
cd $PWD
if [ $? -eq 0 ]; then
	echo ""
	echo "Your driver should now be installed."
	echo ""
fi
