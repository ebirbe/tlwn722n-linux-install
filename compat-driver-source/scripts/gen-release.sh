#!/usr/bin/env bash
# Copyright 2009-2012  Luis R. Rodriguez <mcgrof@do-not-panic.com>
#
# You can use this to make compat-drivers releases:
#
#   * daily linux-next.git based compat-drivers releases
#   * linux-stable.git / linux.git stable releases
#
# The assumption is you have the linux-stable git tree on your $HOME
#
# git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
# git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
#
# You can add linux.git on to your linux-stable.git as a remote to get
# Linus's RC's and you should add linux-stable.git as a local remote
# to your linux-next.git so you can get then get the linux-stable tags
# for your linux-next.git tree.
#
# By default we refer to the GIT_TREE variable for where we are pulling
# code for a release and guestimate what type of release you want
# from that. By default we assume you want a daily linux-next.git tree
# release.

# Pretty colors
GREEN="\033[01;32m"
YELLOW="\033[01;33m"
NORMAL="\033[00m"
BLUE="\033[34m"
RED="\033[31m"
PURPLE="\033[35m"
CYAN="\033[36m"
UNDERLINE="\033[02m"

GIT_STABLE_URL="git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git"
GIT_NEXT_URL="git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git"

STABLE_TREE="linux-stable"
NEXT_TREE="linux-next"

STAGING=/tmp/staging/compat-drivers/

GIT_DIRS="$GIT_DIRS $HOME/compat/"
GIT_DIRS="$GIT_DIRS $HOME/devel/compat-drivers/"
GIT_DIRS="$GIT_DIRS $HOME/linux-next/"
GIT_DIRS="$GIT_DIRS $HOME/linux-stable/"

export GIT_DIRS="$GIT_DIRS"

function usage()
{
	echo -e "Usage:"
	echo -e ""
	echo -e "export GIT_TREE=${HOME}/linux-stable/"
	echo -e "or"
	echo -e "export GIT_TREE=${HOME}/linux-next/"
	echo -e ""
	echo -e "${GREEN}$1${NORMAL} ${BLUE}[ -s | -n | -p | -c | -r | -k ]${NORMAL}"
	echo -e ""
	echo -e "-s apply ${BLUE}pending-stable/${NORMAL}             patches"
	echo -e "-n apply ${BLUE}linux-next-cherry-picks/${NORMAL}    patches"
	echo -e "-p apply ${BLUE}linux-next-pending/${NORMAL}         patches"
	echo -e "-c apply ${BLUE}crap/${NORMAL}                       patches"
	echo -e "-u apply ${BLUE}unified-drivers/${NORMAL}	      patches"
	echo -e ""
	echo -e "-k run ${GREEN}git clean -x -d -f${NORMAL} for you, ${RED}not for the faint of heart${NORMAL}"
	echo -e "-r release to kernel.org"
	echo
	echo Examples usages:
	echo
	echo -e "export GIT_TREE=${HOME}/linux-stable/"
	echo -e "${PURPLE}${1} -s -n -p -c${NORMAL}"
	echo or
	echo -e "export GIT_TREE=${HOME}/linux-next/"
	echo -e "${PURPLE}${1} -p -c${NORMAL}"
	echo
	exit
}

UPDATE_ARGS=""
POSTFIX_RELEASE_TAG="-"
USE_KUP=""
FORCE_CLEAN=""

if [ -z $GIT_TREE ]; then
	export GIT_TREE=$HOME/$NEXT_TREE
	if [ ! -d $GIT_TREE ]; then
		echo "Please tell me where your linux-next or linux-stable git tree is."
		echo "You can do this by exporting its location as follows:"
		echo
		echo "  export GIT_TREE=${HOME}/linux-next/"
		echo "or"
		echo "  export GIT_TREE=${HOME}/linux-stable/"
		echo
		echo "If you do not have one you can clone the repositories at:"
		echo "  git clone $GIT_STABLE_URL"
		echo "  git clone $GIT_NEXT_URL"
		exit 1
	fi
else
	echo "You said to use git tree at: $GIT_TREE"
	GIT_DIRS="$GIT_DIRS $GIT_TREE"
fi

COMPAT_DRIVERS_DIR=$(pwd)
COMPAT_DRIVERS_BRANCH=$(git branch | grep \* | awk '{print $2}')

cd $GIT_TREE
# --abbrev=0 on branch should work but I guess it doesn't on some releases
EXISTING_BRANCH=$(git branch | grep \* | awk '{print $2}')

# target branch we want to use from hpa's tree, by default
# this respects the existing branch on the target kernel.
# You can override the target branch by specifying an argument
# to this script.
TARGET_BRANCH="$EXISTING_BRANCH"
TARGET_TAG="$(git describe)"

while [ $# -ne 0 ]; do
	if [[ "$1" = "-s" ]]; then
		UPDATE_ARGS="${UPDATE_ARGS} $1"
		POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}s"
		shift; continue;
	fi
	if [[ "$1" = "-n" ]]; then
		UPDATE_ARGS="${UPDATE_ARGS} $1"
		POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}n"
		shift; continue;
	fi
	if [[ "$1" = "-p" ]]; then
		UPDATE_ARGS="${UPDATE_ARGS} $1"
		POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}p"
		shift; continue;
	fi
	if [[ "$1" = "-c" ]]; then
		UPDATE_ARGS="${UPDATE_ARGS} $1"
		POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}c"
		shift; continue;
	fi
	if [[ "$1" = "-u" ]]; then
		UPDATE_ARGS="${UPDATE_ARGS} $1"
		POSTFIX_RELEASE_TAG="${POSTFIX_RELEASE_TAG}u"
		shift; continue;
	fi

	if [[ "$1" = "-r" ]]; then
		USE_KUP="1"
		shift; continue;
	fi

	if [[ "$1" = "-k" ]]; then
		FORCE_CLEAN="1"
		shift; continue;
	fi

	echo -e "Unexpected argument passed: ${RED}${1}${NORMAL}"
	usage $0
	exit
done

BASE_TREE=$(basename $GIT_TREE)

echo "On ${BASE_TREE}: $TARGET_BRANCH"

# Lets now make sure you are on matching compat-drivers branch.
# This is a super hack, but let me know if you figure out a cleaner way
TARGET_KERNEL_RELEASE=$(make VERSION="linux-3" SUBLEVEL="" EXTRAVERSION=".y" kernelversion)
GENLOG_TARGET=$(make VERSION="3" SUBLEVEL="" EXTRAVERSION="" kernelversion)

if [[ $COMPAT_DRIVERS_BRANCH != $TARGET_KERNEL_RELEASE && $BASE_TREE != "linux-next" ]]; then
	echo -e "You are on the compat-drivers ${GREEN}${COMPAT_DRIVERS_BRANCH}${NORMAL} but are "
	echo -en "on the ${RED}${TARGET_KERNEL_RELEASE}${NORMAL} branch... "
	echo -e "try changing to that first."

	read -p "Do you still want to continue (y/N)? "
	if [[ "${REPLY}" != "y" ]]; then
	    echo -e "Bailing out !"
	    exit
	fi
fi

cd $COMPAT_DRIVERS_DIR
CHANGELOG_FILE="ChangeLog-$(git describe| sed -e 's|compat-drivers-v||')"


if [[ $COMPAT_DRIVERS_BRANCH != "master" ]]; then
	RELEASE=$(git describe --abbrev=0 | sed -e 's|\(v\)\([0-9]\)|\2|')
else
	RELEASE=$(git describe --abbrev=0)
fi

if [[ $POSTFIX_RELEASE_TAG != "-" ]]; then
	RELEASE="${RELEASE}${POSTFIX_RELEASE_TAG}"
fi
RELEASE_TAR="$RELEASE.tar.bz2"

rm -rf $STAGING
mkdir -p $STAGING
cp -a $COMPAT_DRIVERS_DIR $STAGING/$RELEASE
cd $STAGING/$RELEASE

# Only use interactive paranoia for non-signed / uploaded to kernel.org releases
# If using kup note that we will from now on always be forcing a super clean
# release and will simply use git clean to help use remove all detected content
# that should not be on your local git tree as after a checkout.
PARANOIA=""
if [[ "$USE_KUP" != "1" ]]; then
	PARANOIA="-i"
else
	PARANOIA="-c"
fi

if [[ "$FORCE_CLEAN" = "1" ]]; then
	PARANOIA="$PARANOIA -c"
fi

./scripts/git-paranoia $PARANOIA
if [[ $? -ne 0 ]]; then
	if [[ "$USE_KUP" = "1" ]]; then
		echo -e "Given that this is a targeted ${CYAN}kernel.org${NORMAL}"
		echo -e "release we are bailing."
		exit 1
	fi
	echo
	echo -e "Detected some tree content is not yet ${RED}GPG signed${NORMAL}..."
	echo -e "Consider ${CYAN}baling out${NORMAL} and ${RED}carefully${NORMAL} reading the"
	echo -e "implications of running ${GREEN}$0 -k${NORMAL} instead."
	echo -e "If you make a release right now you may be included files"
	echo -e "or code into the release you perhaps did not want to."
	echo -e ""
	read -p "Do you still want to continue (y/N)? "
	if [[ "${REPLY}" != "y" ]]; then
	    echo -e "Bailing out !"
	    exit 1
	fi
fi

./scripts/admin-update.sh $UPDATE_ARGS
rm -rf $STAGING/$RELEASE/.git

# Remove any gunk
echo
echo "Cleaning up the release ..."
make clean 2>&1 > /dev/null
find ./ -type f -name *.orig | xargs rm -f
find ./ -type f -name *.rej  | xargs rm -f

cd $STAGING/

echo "Creating ${RELEASE}.tar ..."
tar -cf ${RELEASE}.tar $RELEASE/
bzip2 -k -9 ${RELEASE}.tar

# kup allows us to upload a compressed archive but wants us
# to sign the tarball alone, it will uncompress the
# compressed tarball, verify the tarball and then re-compress
# the tarball.
gpg --armor --detach-sign ${RELEASE}.tar

echo
echo "compat-drivers release: $RELEASE"
echo "Size: $(du -h ${RELEASE_TAR})"
echo "sha1sum: $(sha1sum ${RELEASE_TAR})"
echo
echo "Release:           ${STAGING}${RELEASE_TAR}"
echo "Release signature: ${STAGING}${RELEASE}.tar.asc"

if [[ "$USE_KUP" != "1" ]]; then
	exit 0
fi

# Where we dump backport releases onto kernel.org
KORG_BACKPORT="/pub/linux/kernel/projects/backports/"

if [[ "$BASE_TREE" = "linux-next" ]]; then
	YEAR=$(echo $TARGET_TAG | awk -F "-" '{print $2}' | cut -c 1-4)
	MONTH=$(echo $TARGET_TAG | awk -F "-" '{print $2}' | cut -c 5-6)
	DAY=$(echo $TARGET_TAG | awk -F "-" '{print $2}' | cut -c 7-8)


	kup mkdir ${KORG_BACKPORT}/${YEAR} > /dev/null 2>&1
	kup mkdir ${KORG_BACKPORT}/${YEAR}/${MONTH} > /dev/null 2>&1
	kup mkdir ${KORG_BACKPORT}/${YEAR}/${MONTH}/${DAY} > /dev/null 2>&1

	kup ls ${KORG_BACKPORT}/${YEAR}/${MONTH}/${DAY}/ | grep ${RELEASE}.tar.bz2 > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		echo -e "File ${KORG_BACKPORT}/${YEAR}/${MONTH}/${DAY}/${BLUE}${RELEASE}.tar.bz2${NORMAL} already exists"
	fi

	kup put ${RELEASE}.tar.bz2 ${RELEASE}.tar.asc ${KORG_BACKPORT}/${YEAR}/${MONTH}/${DAY}/
elif [[ "$BASE_TREE" = "linux-stable" ]]; then
	TARGET_STABLE="${KORG_BACKPORT}/stable/${TARGET_TAG}"

	kup mkdir ${KORG_BACKPORT}/stable > /dev/null 2>&1
	kup mkdir ${TARGET_STABLE} > /dev/null 2>&1

	kup ls ${TARGET_STABLE} | grep ${RELEASE}.tar.bz2 > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		echo -e "File ${TARGET_STABLE}/${RELEASE}.tar.bz2${NORMAL} already exists"
	fi

	kup put ${RELEASE}.tar.bz2 ${RELEASE}.tar.asc ${TARGET_STABLE}/

	cd $GIT_TREE
	$STAGING/${RELEASE}/scripts/genlog-${GENLOG_TARGET}

	gpg --armor --detach-sign $CHANGELOG_FILE
	kup put ${CHANGELOG_FILE} ${CHANGELOG_FILE}.asc ${TARGET_STABLE}/
else
	echo "Unsupported release type: $BASE_TREE"
	exit 1
fi
