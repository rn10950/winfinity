#!/bin/bash
#Debian 13 "Trixie" Only
#run as root or with sudo
#script will enable contrib and non-free repositories
#set WINF_POSTINSTALL to the path of a script to run after main package install
#
#
#		Winfinity Debian 13 Trixie Bootstrap Installer
#
#

# define vars
winfinityGitUrl="https://github.com/rn10950/winfinity.git"
WINFINITY_SOURCE_DIR="/var/tmp/winfinity-source"
IS_BOOTSTRAP="1"

# install git and first round of dependencies (to save time later)
apt-get -y install git wget dialog curl rsync

# clone source dir into temporary directory
git clone "$winfinityGitUrl" "$WINFINITY_SOURCE_DIR"

# change into downloaded source directory
cd "$WINFINITY_SOURCE_DIR"

#echo "Script Working Directory: $PWD"

# run installer
source $PWD/debian13.sh