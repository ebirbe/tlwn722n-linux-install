# tlwn722n-linux-install

An automatic installer for Wireless USB device "TP-LINK TL-WN722N" or 
any other that uses the Atheros "htc_9271" firmware.

Copyright (C) 2011 Erick Birbe <erickcion@gmail.com>

This program is free software; you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the 
Free Software Foundation; either version 2 of the License, or (at your 
option) any later version.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
General Public License for more details.

You should have received a copy of the GNU General Public License along 
with this program; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Requirements:

The following applications are required before run the install script:

* linux-headers-\[version\] (Where \[version\] is your specific kernel 
 version and architecture, example: linux-headers-2.6.32-5-amd64)
* make
* tar
* wget

You can install the required applications with the next command as root
(only in debian based systems):

 ```bash
 apt-get install make tar wget linux-header-$(uname -r)
 ```

If you have a debian based system and other active internet connection,
the linux-headers-[version] will automatically be installed by the 
install script via apt-get.
