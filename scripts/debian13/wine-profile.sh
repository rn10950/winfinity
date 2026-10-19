#!/bin/bash


# configure WINE
if [ "$(whoami)" = "$TDE_USER" ]; then
	WINEARCH=win32 wine start /? > /dev/null
	echo "wineserver -p" >> ~/.bashrc
elif [ "$(whoami)" = "root" ]; then
	runuser -l $TDE_USER -c 'WINEARCH=win32 wine start /?' > /dev/null
	echo "wineserver -p" >> $TDE_USERPROFILE/.bashrc
else
	echo "WINE configuration failed, setup must be run by '$TDE_USER' or root"
fi