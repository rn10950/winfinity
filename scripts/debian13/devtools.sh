#!/bin/bash

# Winfinity dev tools installer
# Debian 13 Trixie only
# Run as root or with sudo

# $sD = winfinity system directory (typically /opt/winfinity)

awfD="$sD/dev-tools/awf"

apt-get -y install git build-essential libgtk2.0-dev libgtk-3-dev automake \
	kmenuedit-trinity kdiff3-trinity tdevelop-trinity 
apt-get -y install --no-install-recommends xinit twm xterm nano mc
git clone https://github.com/valr/awf $awfD
pushd $awfD
./autogen.sh
./configure
make
make install
popd
