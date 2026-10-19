#!/bin/bash
source "$VARS"

# Winfinity TDM module
#
# Must be run from within module installer enviornment

# determine if system install and tdm enabled
if [[ "$INSTALL_SYS" == "1" && "$INSTALL_TDM" == "1" ]]
then
	cp -rp "$mD/tdm" /etc/trinity/
	chmod -R a+rX /etc/trinity/tdm
fi