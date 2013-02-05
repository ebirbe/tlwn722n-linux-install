#!/usr/bin/env bash
# 
# Copyright 2007, 2008, 2010	Luis R. Rodriguez <mcgrof@winlab.rutgers.edu>
#
# Use this to update compat-drivers to the latest
# linux-next.git tree you have.
#
# Usage: you should have the latest pull of linux-next.git
# git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
# We assume you have it on your ~/linux-next/ directory. If you do,
# just run this script from the compat-drivers directory.
# You can specify where your GIT_TREE is by doing:
#
# export GIT_TREE=/home/mcgrof/linux-next/

# Pretty colors
GREEN="\033[01;32m"
YELLOW="\033[01;33m"
NORMAL="\033[00m"
BLUE="\033[34m"
RED="\033[31m"
PURPLE="\033[35m"
CYAN="\033[36m"
UNDERLINE="\033[02m"

# File in which code metrics will be written
CODE_METRICS=code-metrics.txt

# The GIT URL's for linux-next and compat trees
GIT_URL="git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git"
GIT_COMPAT_URL="git://github.com/mcgrof/compat.git"

####################
# Helper functions #
# ##################

# Refresh patches using quilt
patchRefresh() {
	if [ -d .pc ] ; then
		OLD_PATCH_DIR=$(cat .pc/.quilt_patches)
		if [ "$OLD_PATCH_DIR" != "$1" ] ; then
			echo "found old quilt run for ${OLD_PATCH_DIR}, will skip it for ${1}"
			return;
		fi
	fi

	if [ -d patches.orig ] ; then
		rm -rf .pc patches/series
	else
		mkdir patches.orig
	fi

	export QUILT_PATCHES=$1

	mv -u $1/* patches.orig/

	for i in patches.orig/*.patch; do
		if [ ! -f "$i" ]; then
			echo -e "${RED}No patches found in $1${NORMAL}"
			break;
		fi
		echo -e "${GREEN}Refresh backport patch${NORMAL}: ${BLUE}${1}/$(basename $i)${NORMAL}"
		quilt import $i
		quilt push -f
		RET=$?
		if [[ $RET -ne 0 ]]; then
			echo -e "${RED}Refreshing $i failed${NORMAL}, update it"
			echo -e "use ${CYAN}quilt edit [filename]${NORMAL} to apply the failed part manually"
			echo -e "use ${CYAN}quilt refresh${NORMAL} after the files are corrected and rerun this script"
			cp patches.orig/README $1/README
			exit $RET
		fi
		QUILT_DIFF_OPTS="-p" quilt refresh -p ab --no-index --no-timestamp
	done
	quilt pop -a

	rm -rf patches.orig .pc $1/series
}

###
# usage() function
###
usage() {
	printf "Usage: $0 [refresh] [ --help | -h | -b | -s | -n | -p | -c [ -u ] [subsystems]
       where subsystems can be network, drm or both. Network is enabled by default.\n\n"

	printf "${GREEN}%10s${NORMAL} - Update all your patch offsets using quilt\n" "refresh"
	printf "${GREEN}%10s${NORMAL} - Only copy over compat code, do not copy driver code\n" "-b"
	printf "${GREEN}%10s${NORMAL} - Get and apply pending-stable/ fixes purging old files there\n" "-s"
	printf "${GREEN}%10s${NORMAL} - Apply the patches from linux-next-cherry-picks directory\n" "-n"
	printf "${GREEN}%10s${NORMAL} - Apply the patches from linux-next-pending directory\n" "-p"
	printf "${GREEN}%10s${NORMAL} - Apply the patches from crap directory\n" "-c"
	printf "${GREEN}%10s${NORMAL} - Apply the patches from unified directory\n" "-u"
}

###
# Code metrics related functions
# 4 parameters get passed to them:
# (ORIG_CODE, CHANGES, ADD, DEL)
###
brag_backport() {
	COMPAT_FILES_CODE=$(find ./ -type f -name  \*.[ch] | egrep  "^./compat/|include/linux/compat" |
		xargs wc -l | tail -1 | awk '{print $1}')
	let COMPAT_ALL_CHANGES=$2+$COMPAT_FILES_CODE
	printf "${GREEN}%10s${NORMAL} - backport code changes\n" $2
	printf "${GREEN}%10s${NORMAL} - backport code additions\n" $3
	printf "${GREEN}%10s${NORMAL} - backport code deletions\n" $4
	printf "${GREEN}%10s${NORMAL} - backport from compat module\n" $COMPAT_FILES_CODE
	printf "${GREEN}%10s${NORMAL} - total backport code\n" $COMPAT_ALL_CHANGES
	printf "${RED}%10s${NORMAL} - %% of code consists of backport work\n" \
		$(perl -e 'printf("%.4f", 100 * '$COMPAT_ALL_CHANGES' / '$1');')
}

nag_pending_stable() {
	printf "${YELLOW}%10s${NORMAL} - Code changes brought in from pending-stable\n" $2
	printf "${YELLOW}%10s${NORMAL} - Code additions brought in from pending-stable\n" $3
	printf "${YELLOW}%10s${NORMAL} - Code deletions brought in from pending-stable\n" $4
	printf "${RED}%10s${NORMAL} - %% of code being cherry picked from pending-stable\n" $(perl -e 'printf("%.4f", 100 * '$2' / '$1');')
}

nag_next_cherry_pick() {
	printf "${YELLOW}%10s${NORMAL} - Code changes brought in from linux-next\n" $2
	printf "${YELLOW}%10s${NORMAL} - Code additions brought in from linux-next\n" $3
	printf "${YELLOW}%10s${NORMAL} - Code deletions brought in from linux-next\n" $4
	printf "${RED}%10s${NORMAL} - %% of code being cherry picked from linux-next\n" $(perl -e 'printf("%.4f", 100 * '$2' / '$1');')
}

nag_pending() {
	printf "${YELLOW}%10s${NORMAL} - Code changes posted but not yet merged\n" $2
	printf "${YELLOW}%10s${NORMAL} - Code additions posted but not yet merged\n" $3
	printf "${YELLOW}%10s${NORMAL} - Code deletions posted but not yet merged\n" $4
	printf "${RED}%10s${NORMAL} - %% of code not yet merged\n" $(perl -e 'printf("%.4f", 100 * '$2' / '$1');')
}

nag_crap() {
	printf "${RED}%10s${NORMAL} - Crap changes not yet posted\n" $2
	printf "${RED}%10s${NORMAL} - Crap additions not yet posted\n" $3
	printf "${RED}%10s${NORMAL} - Crap deletions not yet posted\n" $4
	printf "${RED}%10s${NORMAL} - %% of crap code\n" $(perl -e 'printf("%.4f", 100 * '$2' / '$1');')
}

nag_unified() {
	printf "${RED}%10s${NORMAL} - Unified driver backport changes required to backport\n" $2
	printf "${RED}%10s${NORMAL} - Unified driver backport additions required\n" $3
	printf "${RED}%10s${NORMAL} - Unified driver backport deletions required\n" $4
	printf "${RED}%10s${NORMAL} - %% of unified backport code\n" $(perl -e 'printf("%.4f", 100 * '$2' / '$1');')
}

nagometer() {
	CHANGES=0

	ORIG_CODE=$2
	ADD=$(grep -Hc ^+ $1/*.patch| awk -F":" 'BEGIN {sum=0} {sum += $2} END { print sum}')
	DEL=$(grep -Hc ^- $1/*.patch| awk -F":" 'BEGIN {sum=0} {sum += $2} END { print sum}')
	# Total code is irrelevant unless you take into account each part,
	# easier to just compare against the original code.
	# let TOTAL_CODE=$ORIG_CODE+$ADD-$DEL

	let CHANGES=$ADD+$DEL

	case `dirname $1` in
	"patches/collateral-evolutions")
		brag_backport $ORIG_CODE $CHANGES $ADD $DEL
		;;
	"patches/pending-stable")
		nag_pending_stable $ORIG_CODE $CHANGES $ADD $DEL
		;;
	"patches/linux-next-cherry-picks")
		nag_next_cherry_pick $ORIG_CODE $CHANGES $ADD $DEL
		;;
	"patches/linux-next-pending")
		nag_pending $ORIG_CODE $CHANGES $ADD $DEL
		;;
	"patches/crap")
		nag_crap $ORIG_CODE $CHANGES $ADD $DEL
		;;
	"patches/unified-drivers")
		nag_unified $ORIG_CODE $CHANGES $ADD $DEL
		;;
	*)
		;;
	esac

}

# Copy each file in $1 into $2
copyFiles() {
	FILES=$1
	TARGET=$2
	for file in $FILES; do
		echo "Copying $GIT_TREE/$TARGET/$file"
		cp "$GIT_TREE/$TARGET/$file" $TARGET/
	done
}

copyDirectories() {
	DIRS=$1
	for dir in $DIRS; do
		echo "Copying $GIT_TREE/$dir/*.[ch]"
		cp $GIT_TREE/$dir/{Kconfig,Makefile,*.[ch]} $dir/ &> /dev/null
	done
}

# First check cmdline args to understand
# which patches to apply and which release tag to set.
#
# Release tags (with corresponding cmdline switches):
# ---------------------------------------------------
# 	s: Include pending-stable/ patches		(-s)
# 	n: Include linux-next-cherry-picks/ patches	(-n)
# 	p: Include linux-next-pending/ patches		(-p)
# 	c: Include crap/ patches			(-c)
# 	u: Include unified-drivers/ patches		(-u)
# Note that the patches under patches/collateral-evolutions/{subsystem}
# are applied by default.
#
# If "refresh" is given as a cmdline argument, the script
# uses quilt to refresh the patches. This is useful if patches
# can not be applied correctly after a code update in $GIT_URL.
#
# A final parameter drm, wlan or both determines which subsystem
# drivers will be fetched in from the GIT repository. To retain
# compatibility with compat-wireless, wlan/bt/eth drivers are
# fetched in by default.
ENABLE_NETWORK=1
ENABLE_DRM=1
ENABLE_UNIFIED=0
SUBSYSTEMS=
UNIFIED_DRIVERS=

EXTRA_PATCHES="patches/collateral-evolutions"
REFRESH="n"
GET_STABLE_PENDING="n"
POSTFIX_RELEASE_TAG=""

# User exported this variable
if [ -z $GIT_TREE ]; then
	GIT_TREE="$HOME/linux-next"
	if [ ! -d $GIT_TREE ]; then
		echo "Please tell me where your linux-next git tree is."
		echo "You can do this by exporting its location as follows:"
		echo
		echo "  export GIT_TREE=$HOME/linux-next"
		echo
		echo "If you do not have one you can clone the repository:"
		echo "  git clone $GIT_URL"
		echo
		echo "Alternatively, you can use get-compat-trees script "
		echo "from compat.git tree to fetch the necessary trees."
		exit 1
	fi
else
	echo "You said to use git tree at: $GIT_TREE for linux-next"
fi

if [ -z $GIT_COMPAT_TREE ]; then
	GIT_COMPAT_TREE="$HOME/compat"
	if [ ! -d $GIT_COMPAT_TREE ]; then
		echo "Please tell me where your compat git tree is."
		echo "You can do this by exporting its location as follows:"
		echo
		echo "  export GIT_COMPAT_TREE=$HOME/compat"
		echo
		echo "If you do not have one you can clone the repository:"
		echo "  git clone $GIT_COMPAT_URL"
		echo
		echo "Alternatively, you can use get-compat-trees script "
		echo "from compat.git tree to fetch the necessary trees."
		exit 1
	fi
else
	echo "You said to use git tree at: $GIT_COMPAT_TREE for compat"
fi

# Now define what files to copy from $GIT_URL
INCLUDE_NET_BT="hci_core.h
		l2cap.h
		bluetooth.h
		rfcomm.h
		hci.h
		hci_mon.h
		mgmt.h
		sco.h
		smp.h
		a2mp.h
		amp.h"

# Required wlan headers from include/linux
INCLUDE_LINUX_WLAN="ieee80211.h
		    pci_ids.h
		    eeprom_93cx6.h
		    ath9k_platform.h
		    wl12xx.h
		    rndis.h
		    bcm47xx_wdt.h"

# For rndis_wext
INCLUDE_LINUX_USB_WLAN="usbnet.h
		        rndis_host.h"

# For rndis_wlan, we need a new rndis_host.ko, cdc_ether.ko and usbnet.ko
RNDIS_REQUIREMENTS="Makefile
		    rndis_host.c
		    cdc_ether.c
		    usbnet.c"

# For libertas driver
INCLUDE_LINUX_LIBERTAS_WLAN="libertas_spi.h"

# Required wlan headers from include/uapi/linux
INCLUDE_UAPI_LINUX_WLAN="nl80211.h
			 rfkill.h"

# 802.11 related headers
INCLUDE_NET="cfg80211.h
	     cfg80211-wext.h
	     ieee80211_radiotap.h
	     lib80211.h
	     mac80211.h
	     regulatory.h"

# Network related directories
NET_WLAN_DIRS="net/wireless
	       net/mac80211
	       net/rfkill"

# Bluetooth related directories
NET_BT_DIRS="net/bluetooth
	     net/bluetooth/bnep
	     net/bluetooth/cmtp
	     net/bluetooth/rfcomm
	     net/bluetooth/hidp"

# Drivers that have their own directory
DRIVERS_WLAN="drivers/net/wireless/ath
	      drivers/net/wireless/ath/carl9170
	      drivers/net/wireless/ath/ar5523
	      drivers/net/wireless/ath/ath5k
	      drivers/net/wireless/ath/ath6kl
	      drivers/net/wireless/ath/ath9k
	      drivers/net/wireless/ath/wil6210
	      drivers/ssb
	      drivers/bcma
	      drivers/net/wireless/b43
	      drivers/net/wireless/b43legacy
	      drivers/net/wireless/brcm80211
	      drivers/net/wireless/brcm80211/brcmfmac
	      drivers/net/wireless/brcm80211/brcmsmac
	      drivers/net/wireless/brcm80211/brcmsmac/phy
	      drivers/net/wireless/brcm80211/brcmutil
	      drivers/net/wireless/brcm80211/include
	      drivers/net/wireless/iwlegacy
	      drivers/net/wireless/iwlwifi
	      drivers/net/wireless/iwlwifi/pcie
	      drivers/net/wireless/iwlwifi/dvm
	      drivers/net/wireless/rt2x00
	      drivers/net/wireless/zd1211rw
	      drivers/net/wireless/libertas
	      drivers/net/wireless/p54
	      drivers/net/wireless/rtl818x
	      drivers/net/wireless/rtl818x/rtl8180
	      drivers/net/wireless/rtl818x/rtl8187
	      drivers/net/wireless/rtlwifi
	      drivers/net/wireless/rtlwifi/rtl8192c
	      drivers/net/wireless/rtlwifi/rtl8192ce
	      drivers/net/wireless/rtlwifi/rtl8192cu
	      drivers/net/wireless/rtlwifi/rtl8192se
	      drivers/net/wireless/rtlwifi/rtl8192de
	      drivers/net/wireless/rtlwifi/rtl8723ae
	      drivers/net/wireless/libertas_tf
	      drivers/net/wireless/ipw2x00
	      drivers/net/wireless/ti
	      drivers/net/wireless/ti/wl12xx
	      drivers/net/wireless/ti/wl1251
	      drivers/net/wireless/ti/wlcore
	      drivers/net/wireless/ti/wl18xx
	      drivers/net/wireless/orinoco
	      drivers/net/wireless/mwifiex"

# Staging drivers
STAGING_DRIVERS=""

# Ethernet drivers having their own directory
DRIVERS_ETH="drivers/net/ethernet/atheros
	     drivers/net/ethernet/atheros/atl1c
	     drivers/net/ethernet/atheros/atl1e
	     drivers/net/ethernet/atheros/atlx"

# Ethernet drivers that have their own file alone
DRIVERS_ETH_FILES="mdio.c"

# Bluetooth drivers
DRIVERS_BT="drivers/bluetooth"

# Drivers that belong the the wireless directory
DRIVERS_WLAN_FILES="adm8211.c
		    adm8211.h
		    at76c50x-usb.c
		    at76c50x-usb.h
		    mac80211_hwsim.c
		    mac80211_hwsim.h
		    mwl8k.c
		    rndis_wlan.c"

# DRM drivers
DRIVERS_DRM="drivers/gpu/drm/ast
	     drivers/gpu/drm/cirrus
	     drivers/gpu/drm/gma500
	     drivers/gpu/drm/i2c
	     drivers/gpu/drm/i810
	     drivers/gpu/drm/i915
	     drivers/gpu/drm/mgag200
	     drivers/gpu/drm/nouveau
	     drivers/gpu/drm/radeon
	     drivers/gpu/drm/ttm
	     drivers/gpu/drm/via
	     drivers/gpu/drm/vmwgfx"

# UDL uses the new dma-buf API, let's disable this for now
#DRIVERS="$DRIVERS drivers/gpu/drm/udl"

rm -rf drivers/
rm -f code-metrics.txt

mkdir -p include/net/bluetooth \
	 include/linux/usb \
	 include/linux/unaligned \
	 include/linux/spi \
	 include/trace \
	 include/pcmcia \
	 include/crypto \
	 include/uapi \
	 include/uapi/linux \
	 drivers/bcma \
	 drivers/misc/eeprom \
	 drivers/net/usb \
	 drivers/net/ethernet/broadcom \
	 drivers/platform/x86 \
	 drivers/ssb \
	 drivers/staging \
	 $NET_WLAN_DIRS \
	 $NET_BT_DIRS \
	 $DRIVERS_WLAN \
	 $DRIVERS_ETH \
	 $DRIVERS_BT \
	 $DRIVERS_DRM



function refresh_compat()
{
	# Compat stuff
	COMPAT="compat"
	mkdir -p $COMPAT
	echo "Copying $GIT_COMPAT_TREE/ files..."
	cp $GIT_COMPAT_TREE/compat/*.[ch] $COMPAT/
	cp $GIT_COMPAT_TREE/compat/Makefile $COMPAT/
	cp -a $GIT_COMPAT_TREE/udev .
	cp -a $GIT_COMPAT_TREE/scripts $COMPAT/
	cp $GIT_COMPAT_TREE/bin/ckmake $COMPAT/
	cp -a $GIT_COMPAT_TREE/include/linux/* include/linux/
	cp -a $GIT_COMPAT_TREE/include/net/* include/net/
	cp -a $GIT_COMPAT_TREE/include/trace/* include/trace/
	cp -a $GIT_COMPAT_TREE/include/pcmcia/* include/pcmcia/
	cp -a $GIT_COMPAT_TREE/include/crypto/* include/crypto/
}

function gen_compat_labels()
{

	DIR="$PWD"
	cd $GIT_TREE
	GIT_DESCRIBE=$(git describe)
	GIT_BRANCH=$(git branch --no-color |sed -n 's/^\* //p')
	GIT_BRANCH=${GIT_BRANCH:-master}
	GIT_REMOTE=$(git config branch.${GIT_BRANCH}.remote)
	GIT_REMOTE=${GIT_REMOTE:-origin}
	GIT_REMOTE_URL=$(git config remote.${GIT_REMOTE}.url)
	GIT_REMOTE_URL=${GIT_REMOTE_URL:-unknown}

	cd $GIT_COMPAT_TREE
	git describe > $DIR/.compat_base
	cd $DIR

	echo -e "${GREEN}Updated${NORMAL} from local tree: ${BLUE}${GIT_TREE}${NORMAL}"
	echo -e "Origin remote URL: ${CYAN}${GIT_REMOTE_URL}${NORMAL}"
	cd $DIR
	if [ -d ./.git ]; then
		if [[ ${POSTFIX_RELEASE_TAG} != "" ]]; then
			echo -e "$(git describe)-${POSTFIX_RELEASE_TAG}" > .compat_version
		else
			echo -e "$(git describe)" > .compat_version
		fi

		cd $GIT_TREE
		TREE_NAME=${GIT_REMOTE_URL##*/}

		echo $TREE_NAME > $DIR/.compat_base_tree
		echo $GIT_DESCRIBE > $DIR/.compat_base_tree_version

		case $TREE_NAME in
		"wireless-testing.git") # John's wireless-testing
			echo -e "This is a ${RED}wireless-testing.git${NORMAL} compat-drivers release"
			;;
		"linux-next.git") # The linux-next integration testing tree
			echo -e "This is a ${RED}linux-next.git${NORMAL} compat-drivers release"
			;;
		"linux-stable.git") # Greg's all stable tree
			echo -e "This is a ${GREEN}linux-stable.git${NORMAL} compat-drivers release"
			;;
		"linux-2.6.git") # Linus' 2.6 tree
			echo -e "This is a ${GREEN}linux-2.6.git${NORMAL} compat-drivers release"
			;;
		*)
			;;
		esac

		cd $DIR
		echo -e "\nBase tree: ${GREEN}$(cat .compat_base_tree)${NORMAL}" >> $CODE_METRICS
		echo -e "Base tree version: ${PURPLE}$(cat .compat_base_tree_version)${NORMAL}" >> $CODE_METRICS
		echo -e "compat.git: ${CYAN}$(cat .compat_base)${NORMAL}" >> $CODE_METRICS
		echo -e "compat-drivers release: ${YELLOW}$(cat .compat_version)${NORMAL}" >> $CODE_METRICS

	fi


	echo -e "Code metrics archive: ${GREEN}http://bit.ly/H6BTF7${NORMAL}" >> $CODE_METRICS

	cat $CODE_METRICS
}


if [ $# -ge 1 ]; then
	if [ $# -gt 6 ]; then
		usage $0
		exit
	fi
	while [ $# -ne 0 ]; do
		case $1 in
			"-b")
				refresh_compat
				gen_compat_labels
				exit
				;;
			"-s")
				GET_STABLE_PENDING="y"
				EXTRA_PATCHES="${EXTRA_PATCHES} patches/pending-stable"
				EXTRA_PATCHES="${EXTRA_PATCHES} patches/pending-stable/backports/"
				POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}s"
				shift
				;;
			"-n")
				EXTRA_PATCHES="${EXTRA_PATCHES} patches/linux-next-cherry-picks"
				POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}n"
				shift
				;;
			"-p")
				EXTRA_PATCHES="${EXTRA_PATCHES} patches/linux-next-pending"
				POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}p"
				shift
				;;
			"-c")
				EXTRA_PATCHES="${EXTRA_PATCHES} patches/crap"
				POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}c"
				shift
				;;
			"-u")
				EXTRA_PATCHES="${EXTRA_PATCHES} patches/unified-drivers"
				POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}u"
				ENABLE_UNIFIED=1
				shift
				;;
			"refresh")
				REFRESH="y"
				shift
				;;
			"network")
				ENABLE_NETWORK=1
				ENABLE_DRM=0
				shift
				;;
			"drm")
				ENABLE_DRM=1
				shift
				;;
			"-h" | "--help")
				usage $0
				exit
				;;
			*)
				echo "Unexpected argument passed: $1"
				usage $0
				exit
				;;
		esac
	done

fi

# SUBSYSTEMS is used to select which patches to apply
if [[ "$ENABLE_NETWORK" == "1" ]]; then
	SUBSYSTEMS="network"
fi

if [[ "$ENABLE_DRM" == "1" ]]; then
	SUBSYSTEMS+=" drm"
fi

if [[ "$ENABLE_NETWORK" == "1" ]]; then
	# WLAN and bluetooth files
	copyFiles "$INCLUDE_LINUX_WLAN"			"include/linux"
	copyFiles "$INCLUDE_UAPI_LINUX_WLAN"		"include/uapi/linux"
	copyFiles "$INCLUDE_NET"			"include/net"
	copyFiles "$INCLUDE_NET_BT" 			"include/net/bluetooth"
	copyFiles "$INCLUDE_LINUX_USB_WLAN"		"include/linux/usb"
	copyFiles "$INCLUDE_LINUX_LIBERTAS_WLAN"	"include/linux/spi"
	copyFiles "$DRIVERS_WLAN_FILES"			"drivers/net/wireless"
	copyFiles "$RNDIS_REQUIREMENTS"			"drivers/net/usb"

	# Ethernet
	copyFiles "$DRIVERS_ETH_FILES"			"drivers/net/"
	echo "compat_mdio-y                      += mdio.o" > drivers/net/Makefile
	echo "obj-\$(CONFIG_COMPAT_MDIO)          += compat_mdio.o" >> drivers/net/Makefile
	copyDirectories "$DRIVERS_ETH"
	cp $GIT_TREE/include/linux/mdio.h include/linux/
	cp $GIT_TREE/include/uapi/linux/mdio.h include/uapi/linux/

	copyDirectories "$NET_WLAN_DIRS"
	copyDirectories "$NET_BT_DIRS"
	copyDirectories "$DRIVERS_BT"
	copyDirectories "$DRIVERS_WLAN"

	cp -a $GIT_TREE/include/linux/ssb include/linux/
	cp -a $GIT_TREE/include/linux/bcma include/linux/
	cp -a $GIT_TREE/include/linux/rfkill.h include/linux/rfkill_backport.h
	mv include/uapi/linux/rfkill.h include/uapi/linux/rfkill_backport.h

	# Misc
	cp $GIT_TREE/drivers/misc/eeprom/{Makefile,eeprom_93cx6.c} drivers/misc/eeprom/

	# Copy files needed for statically compiled regulatory rules database
	cp $GIT_TREE/net/wireless/{db.txt,genregdb.awk} net/wireless/

	# Top level wireless driver Makefile
	cp $GIT_TREE/drivers/net/wireless/Makefile drivers/net/wireless

	# Broadcom case
	DIR="drivers/net/ethernet/broadcom"
	cp $GIT_TREE/$DIR/b44.[ch] drivers/net/ethernet/broadcom
	# Not yet
	echo "obj-\$(CONFIG_B44) += b44.o" > drivers/net/ethernet/broadcom/Makefile
fi

if [[ "$ENABLE_DRM" == "1" ]]; then
	# DRM drivers
	copyDirectories "$DRIVERS_DRM"

	# Copy standalone drivers
	echo "Copying $GIT_TREE/drivers/gpu/drm/*.[ch]"
	cp $GIT_TREE/drivers/gpu/drm/{Makefile,*.[ch]} drivers/gpu/drm/

	# Copy DRM headers
	cp -a $GIT_TREE/include/drm include/

	# Copy UAPI DRM headers
	cp -a $GIT_TREE/include/uapi/drm include/uapi/

	# drivers/gpu/drm/i915/intel_pm.c requires this
	cp $GIT_TREE/drivers/platform/x86/intel_ips.h drivers/platform/x86

	# Copy radeon reg_srcs for hostprogs
	cp -a $GIT_TREE/drivers/gpu/drm/radeon/reg_srcs drivers/gpu/drm/radeon

	# Copy core/ from nouveau/ (Introduced after new code rewrite in 3.7)
	cp -a $GIT_TREE/drivers/gpu/drm/nouveau/core drivers/gpu/drm/nouveau

	# Finally get the DRM top-level makefile
	cp $GIT_TREE/drivers/gpu/drm/Makefile drivers/gpu/drm
else
	touch drivers/gpu/drm/Makefile
fi

# Staging drivers in their own directory
for i in $STAGING_DRIVERS; do
	if [ ! -d $GIT_TREE/$i ]; then
		continue
	fi
	rm -rf $i
	echo -e "Copying ${RED}STAGING${NORMAL} $GIT_TREE/$i/*.[ch]"
	# staging drivers tend to have their own subdirs...
	cp -a $GIT_TREE/$i drivers/staging/
done

UNIFIED_DRIVERS+="alx"

unified_driver_git_tree() {
	case $1 in
	"alx")
		echo "git://github.com/mcgrof/alx.git"
		;;
	*)
		;;
	esac
}

unified_driver_linux_next_target() {
	case $1 in
	"alx")
		echo "drivers/net/ethernet/atheros/alx"
		;;
	*)
		;;
	esac
}

unified_driver_get_linux_src() {
	case $1 in
	"alx")
		make -C $DRV_SRC/ linux-src

		TARGET_NEXT_DIR="$(unified_driver_linux_next_target $i)"

		rm -rf $TARGET_NEXT_DIR
		cp -a $DRV_SRC/target/linux/src $TARGET_NEXT_DIR
		;;
	*)
		echo "Unsupported unified driver: $1"
		exit
		;;
	esac
}

if [[ "$ENABLE_UNIFIED" == "1" ]]; then
	if [ -z $UNIFIED_SRC ]; then
		UNIFIED_SRC="$HOME/unified"
		if [ ! -d $UNIFIED_SRC ]; then
			echo "The directory $UNIFIED_SRC does not exist"
			echo
			echo "Please tell me where your unified drivers are located"
			echo "You can do this by exporting its location as follows:"
			echo
			echo "  export UNIFIED_SRC=$HOME/unified"
			echo
			echo "If you have never downloaded unified driver code you"
			echo "can simply re-run this script by first creating an"
			echo "empty directory for on $HOME/unified, the script"
			echo "will then tell you what trees to clone. The unified"
			echo "drivers that we support in compat-drivers adhear to"
			echo "a policy explained in unified/README.md"
			exit 1
		fi
	else
		if [ ! -d $UNIFIED_SRC ]; then
			echo "The directory $UNIFIED_SRC does not exist"
			exit
		fi
	fi

	for i in $UNIFIED_DRIVERS; do
		DRV_SRC="$UNIFIED_SRC/$i"

		if [ ! -d $DRV_SRC ]; then
			echo -e "$DRV_SRC does not exist. You can clone this tree from:"
			echo
			unified_driver_git_tree $i
			echo
			echo "You should clone this into $UNIFIED_SRC directory or"
			echo "later specify where you put it using the UNIFIED_SRC"
			echo "environment variable"
			exit 1
		fi

		unified_driver_get_linux_src $i
	done
fi


# Finally copy MAINTAINERS file
cp $GIT_TREE/MAINTAINERS ./

refresh_compat

# Clean up possible *.mod.c leftovers
find -type f -name "*.mod.c" -exec rm -f {} \;

# files we suck in for wireless drivers
export WSTABLE="
	net/wireless/
	net/mac80211/
	net/rfkill/
	drivers/net/wireless/
	net/bluetooth/
	drivers/bluetooth/
	drivers/net/ethernet/atheros/atl1c/
	drivers/net/ethernet/atheros/atl1e/
	drivers/net/ethernet/atheros/atlx/
	include/uapi/drm
	include/uapi/linux/nl80211.h
	include/uapi/linux/rfkill.h
	include/linux/rfkill.h
	include/net/mac80211.h
	include/net/regulatory.h
	include/net/bluetooth/amp.h
	include/net/bluetooth/hci.h
	include/net/bluetooth/hci_core.h
	include/net/bluetooth/mgmt.h
	include/net/cfg80211.h"

# Stable pending, if -n was passed
if [[ "$GET_STABLE_PENDING" = y ]]; then

	if [ -z $NEXT_TREE ]; then
		NEXT_TREE="/$HOME/linux-next"
		if [ ! -d $NEXT_TREE ]; then
			echo "Please tell me where your linux-next git tree is."
			echo "You can do this by exporting its location as follows:"
			echo
			echo "  export NEXT_TREE=$HOME/linux-next"
			echo
			echo "If you do not have one you can clone the repository:"
			echo "  git clone git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git"
			exit 1
		fi
	else
		echo "You said to use git tree at: $NEXT_TREE for linux-next"
	fi

	LAST_DIR=$PWD
	cd $GIT_TREE
	if [ -f localversion* ]; then
		echo -e "You should be using a stable tree to use the -s option"
		exit 1
	fi

	# we now assume you are using a stable tree
	cd $GIT_TREE
	LAST_STABLE_UPDATE=$(git describe --abbrev=0)
	cd $NEXT_TREE
	PENDING_STABLE_DIR="pending-stable/"

	rm -rf $PENDING_STABLE_DIR

	git tag -l | grep $LAST_STABLE_UPDATE 2>&1 > /dev/null
	if [[ $? -ne 0 ]]; then
		echo -e "${BLUE}Tag $LAST_STABLE_UPDATE not found on $NEXT_TREE tree: bailing out${NORMAL}"
		exit 1
	fi
	echo -e "${GREEN}Generating stable cherry picks... ${NORMAL}"
	echo -e "\nUsing command on directory $PWD:"
	echo -e "\ngit format-patch --grep=\"stable@vger.kernel.org\" -o $PENDING_STABLE_DIR ${LAST_STABLE_UPDATE}.. $WSTABLE"
	git format-patch --grep="stable@vger.kernel.org" -o $PENDING_STABLE_DIR ${LAST_STABLE_UPDATE}.. $WSTABLE
	if [ ! -d ${LAST_DIR}/${PENDING_STABLE_DIR} ]; then
		echo -e "Assumption that ${LAST_DIR}/${PENDING_STABLE_DIR} directory exists failed"
		exit 1
	fi
	echo -e "${GREEN}Purging old stable cherry picks... ${NORMAL}"
	rm -f ${LAST_DIR}/${PENDING_STABLE_DIR}/*.patch
	cp ${PENDING_STABLE_DIR}/*.patch ${LAST_DIR}/${PENDING_STABLE_DIR}/
	if [ -f ${LAST_DIR}/${PENDING_STABLE_DIR}/.ignore ]; then
		for i in $(cat ${LAST_DIR}/${PENDING_STABLE_DIR}/.ignore) ; do
			echo -e "Skipping $i from generated stable patches..."
			rm -f ${LAST_DIR}/${PENDING_STABLE_DIR}/*$i*
		done
	fi
	echo -e "${GREEN}Updated stable cherry picks, review with git diff and update hunks with ./scripts/admin-update.sh -s refresh${NORMAL}"
	cd $LAST_DIR
fi

ORIG_CODE=$(find ./ -type f -name  \*.[ch] |
	egrep -v "^./compat/|include/linux/compat" |
	xargs wc -l | tail -1 | awk '{print $1}')
printf "\n${CYAN}compat-drivers code metrics${NORMAL}\n\n" > $CODE_METRICS
printf "${PURPLE}%10s${NORMAL} - Total upstream lines of code being pulled\n" $ORIG_CODE >> $CODE_METRICS

for subsystem in $SUBSYSTEMS; do

	printf "\n   ${YELLOW}$subsystem${NORMAL}\n   ----------------------------------------\n" >> $CODE_METRICS

	for dir in $EXTRA_PATCHES; do
		LAST_ELEM=$dir
	done

	for dir in $EXTRA_PATCHES; do
		PATCHDIR="$dir/$subsystem"
		if [[ ! -d $PATCHDIR ]]; then
			echo -e "${RED}Patches: $PATCHDIR empty, skipping...${NORMAL}"
			continue
		fi
		if [[ "$REFRESH" = y ]]; then
			patchRefresh $PATCHDIR
		fi

		FOUND=$(find $PATCHDIR/ -maxdepth 1 -name \*.patch | wc -l)
		if [ $FOUND -eq 0 ]; then
			continue
		fi

		for i in $(ls $PATCHDIR/*.patch); do
			echo -e "${GREEN}Applying backport patch${NORMAL}: ${BLUE}$i${NORMAL}"
			patch -p1 -N -t < $i
			RET=$?
			if [[ $RET -ne 0 ]]; then
				echo -e "${RED}Patching $i failed${NORMAL}, update it"
				exit $RET
			fi
		done
		nagometer $PATCHDIR $ORIG_CODE >> $CODE_METRICS
	done
done

refresh_compat
gen_compat_labels

./scripts/driver-select restore
