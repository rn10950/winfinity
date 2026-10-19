#!/bin/bash
source "$VARS"

# uses custom variables
# must be run from within Winfinity Installer

# install TDE config
TDE_USER_CONFIG_DIR="$HOME_DIR/.trinity/share/config"
mkdir -p $TDE_USER_CONFIG_DIR
echo "{\"mD\": \"$mD\", \"configPath\": \"$TDE_USER_CONFIG_DIR\"}" | python3 $mD/winfinity-config/installer-module.py

# winfinity-config module installer (includes Control Panel)
#
# Must be run from within module installer enviornment

# determine whether system or local install
if [[ "$INSTALL_SYS" == "1" ]]
then
	cp -r "$mD/winfinity-config" "$sD"
	#mkdir -p $HOME_DIR/.trinity/Autostart
	#cp $mD/control-panel/cpanel-install.desktop $HOME_DIR/.trinity/Autostart/
else
	cp -r "$mD/winfinity-config" "$WINF_USER_PREFIX"
fi

# add firstrun.py to WINF_FIRSTRUN
echo "python3 \$WINF_PREFIX/winfinity-config/firstrun.py" >> $WINF_FIRSTRUN