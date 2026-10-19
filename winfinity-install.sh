#!/bin/bash
# Winfinity New Installer

OUTPUT=/tmp/winfinity-temp$((1 + RANDOM % 100))
>$OUTPUT


# check to see if running in source directory or if directory flag passed
if [[ -z $WINFINITY_SOURCE_DIR ]]
then
	if [[ -f "./winfinity.txt" ]]
	then
		wS="$PWD"
	else
		dialog --title "Error" \
		--backtitle "Winfinity Installer" \
		--msgbox "Winfinity Installer must be run from the Winfinity source directory." 15 60
		return 1
		exit 1
	fi
else
	wS="$WINFINITY_SOURCE_DIR"
fi


## load variables script
if [[ -z $VARS ]]
then
	echo "\$VARS must be set."
	return 1
	exit 1
fi
source $VARS


# set temporary directory if not set
if [[ -z $TMPDIR ]]
then
	TMPDIR="/tmp"
fi


# determine user access level and install location
if [ "$(id -u)" -eq 0 ]
then
	# running as root
	wSu=1
	if [[ "$USER" == "root" ]]
	then
		# running as root account, use root as name for now, possibly prompt later
		BASE_USER="root"
	else
		# using sudo
		BASE_USER="$USER"
	fi
else
	# Not running as root
	wSu=0
	BASE_USER="$USER"
fi

# Install core modules - OLD, keep for now
#for subdir in $wS/core/*; do
#	if [ -d "$subdir" ]; then
#		# execute each module's installer, passing variables
#		mD=$subdir \
#		VARS=$VARS \
#			$subdir/install.sh
#	fi
#done

# Install winfinity-config
configDir="$wS/config"
mD=$configDir VARS=$VARS $configDir/install.sh

# Install modules
for subdir in $wS/modules/*; do
	if [ -d "$subdir" ]; then
		# execute each module's installer, passing variables
		mD=$subdir \
		VARS=$VARS \
			$subdir/install.sh
	fi
done

# Install user-defined modules
for subdir in $wS/custom-modules/*; do
	if [ -d "$subdir" ]; then
		# execute each module's installer, passing variables
		mD=$subdir \
		VARS=$VARS \
			$subdir/install.sh
	fi
done


#
# Finish setting up scripts, copy desktop files
mkdir -p $HOME_DIR/.trinity/Autostart
cp "$wS/resources/firstrun.desktop" "$HOME_DIR/.trinity/Autostart/"
cp "$wS/resources/autoexec.desktop" "$HOME_DIR/.trinity/Autostart/"
mkdir -p "$HOME_DIR/.winfinity/scripts"

echo 'rm -f "$HOME/.trinity/Autostart/firstrun.desktop"' >> $WINF_FIRSTRUN

# testing files
#echo 'echo "OK" > $HOME/firstrun.txt' >> $WINF_FIRSTRUN
#echo 'echo "OK" > $HOME/AUTOEXEC.txt' >> $WINF_AUTOEXEC

# fix xdg-open for directories (gio)
printf '%s\n' 'TARGET_DIR="$HOME/.local/share/applications" && mkdir -p "$TARGET_DIR" && echo -e "[Desktop Entry]\nType=Application\nName=Konqueror\nExec=kfmclient openURL %U\nMimeType=inode/directory;x-scheme-handler/file;\nNoDisplay=true" > "$TARGET_DIR/konqueror.desktop" && update-desktop-database "$TARGET_DIR" && gio mime inode/directory konqueror.desktop' >> $WINF_FIRSTRUN


cp $WINF_FIRSTRUN "$HOME_DIR/.winfinity/scripts/firstrun.sh"
cp $WINF_AUTOEXEC "$HOME_DIR/.winfinity/scripts/AUTOEXEC.sh"

#
# Start installing files

# add dry run option
if [[ "$DRY_RUN" != "1" ]]
then

# determine whether system or user install
if [[ "$INSTALL_SYS" == "1" && "$wSu" == "1" ]]
then
	rsync -a --chmod=u=rwX,go=rX "$ROOT_DIR/" "/"
	
	# backup user directory
	rsync -a --chmod=u=rwX,go=rX "$HOME_DIR" "$SYS_WINF_DIR/user-profile"

	# ensure read and execute are set for regular users for files in system winfinity directory
else
	:
fi

# user profile install
if [[ "$wSu" == "0" || "$INSTALL_SYS" == "0" ]]
then
	TMP_USER_DIR=$TMPDIR/winfinity-fs-tmp-$((1 + RANDOM % 1000))
	rsync -a --chown=$BASE_USER:$BASE_USER --chmod=u=rwX,go=rX "$HOME_DIR"/ "$TMP_USER_DIR"
	chown -R "$BASE_USER" "$TMP_USER_DIR"
	rsync -a --chown=$BASE_USER:$BASE_USER --chmod=u=rwX,go=rX "$TMP_USER_DIR/" "/home/$BASE_USER/"
	rm -rf "$TMP_USER_DIR"
else
	for WINF_USER in ${WINF_USERS//,/ }
	do
		TMP_USER_DIR=$TMPDIR/winfinity-fs-tmp-$((1 + RANDOM % 1000))
		rsync -a --chown=$WINF_USER:$WINF_USER --chmod=u=rwX,go=rX "$HOME_DIR"/ "$TMP_USER_DIR"
		chown -R "$WINF_USER" "$TMP_USER_DIR"
		rsync -a --chown=$WINF_USER:$WINF_USER --chmod=u=rwX,go=rX "$TMP_USER_DIR/" "/home/$WINF_USER/"
		rm -rf "$TMP_USER_DIR"
	done
fi

# skel
if [[ "$wSu" == "1" && "$INSTALL_SKEL" == "1" ]]
then
	rsync -a --chmod=u=rwX,go=rX "$HOME_DIR/" /etc/skel/
fi

#rsync -a --chown=user:user --chmod=u=rwX,go=rX /path/to/source/folder/ /home/user/destination/folder/

# end dry run block
fi

# create winfinity-vars
SF=$(mktemp)
if [[ "$INSTALL_SYS" == "1" ]]
then #SYSTEM INSTALL
	echo "sD=\"${sD/$ROOT_DIR/}\"" >> $SF
	echo "TDE_SYS_DIR=\"${TDE_SYS_DIR/$ROOT_DIR/}\"" >> $SF
	echo "SYS_FONT_DIR=\"${SYS_FONT_DIR/$ROOT_DIR/}\"" >> $SF
	echo "SYS_ICON_DIR=\"${SYS_ICON_DIR/$ROOT_DIR/}\"" >> $SF
	echo "SYS_THEM_DIR=\"${SYS_THEM_DIR/$ROOT_DIR/}\"" >> $SF
	echo "SYS_WINF_DIR=\"$SYS_WINF_DIR\"" >> $SF
	echo "optF=\"${optF/$ROOT_DIR/}\"" >> $SF
	echo "WINF_USERS=\"$WINF_USERS\"" >> $SF
	echo "INSTALL_WINE=\"$INSTALL_WINE\"" >> $SF
	echo "INSTALL_SKEL=\"$INSTALL_SKEL\"" >> $SF
	echo "INSTALL_TDM=\"$INSTALL_TDM\"" >> $SF
	echo "TDE_PREFIX=\"${TDE_SYS_DIR/$ROOT_DIR/}\"" >> $SF
	WINF_PREFIX="${sD/$ROOT_DIR/}"
	echo "WINF_PREFIX=\"$WINF_PREFIX\"" >> $SF
	echo "WINF_DEV_TOOLS=\"$WINF_DEV_TOOLS\"" >> $SF
else #PROFILE INSTALL
	echo "TDE_PREFIX=\"\$HOME${TDE_USER_INSTALL_PREFIX/$HOME_DIR/}\"" >> $SF
	WINF_PREFIX="$HOME${WINF_USER_INSTALL_PREFIX/$HOME_DIR/}"
	echo "WINF_PREFIX=\"\$HOME${WINF_USER_INSTALL_PREFIX/$HOME_DIR/}\"" >> $SF
fi #ALL INSTALLS
	echo "WINFINITY_SOURCE_DIR=\"$wS\"" >> $SF
	echo "INSTALL_SYS=\"$INSTALL_SYS\"" >> $SF
	echo "TDE_PROP=\"$TDE_PROP\"" >> $SF
	echo "OS_TYPE=\"$OS_TYPE\"" >> $SF
	echo "winfinityVerbose=\"$winfinityVerbose\"" >> $SF

	echo "TDE_USER_PREFIX=\"\$HOME${TDE_USER_INSTALL_PREFIX/$HOME_DIR/}\"" >> $SF
	echo "WINF_USER_PREFIX=\"\$HOME${WINF_USER_INSTALL_PREFIX/$HOME_DIR/}\"" >> $SF

cp $SF "$WINF_PREFIX/winfinity-vars"

# copy winfinity-vars to all user profiles
if [[ "$wSu" == "1" &&  "$INSTALL_SYS" == "1" ]]
then
	for WINF_USER in ${WINF_USERS//,/ }
	do
		FN="/home/$WINF_USER/.winfinity/winfinity-vars"
		cp $SF $FN
		chown -R "$WINF_USER" "$FN"
	done
	# add to backup default profile and skel
	cp $SF "$SYS_WINF_DIR/user-profile"
	if [[ "$INSTALL_SKEL" == "1" ]]
	then
		cp $SF "/etc/skel/.winfinity/winfinity-vars"
	fi
fi

#old variable file creation code - save for now
# make this system-only for now until profile install is perfected
# if [[ "$INSTALL_SYS" == "1" ]]
# then
# 	SF=$(mktemp)
# 	echo "WINFINITY_SOURCE_DIR=\"$wS\"" >> $SF
# 	echo "INSTALL_SYS=\"$INSTALL_SYS\"" >> $SF
# 	echo "TDE_PROP=\"$TDE_PROP\"" >> $SF
# 	echo "sD=\"${sD/$ROOT_DIR/}\"" >> $SF
# 	echo "TDE_SYS_DIR=\"${TDE_SYS_DIR/$ROOT_DIR/}\"" >> $SF
# 	echo "SYS_FONT_DIR=\"${SYS_FONT_DIR/$ROOT_DIR/}\"" >> $SF
# 	echo "SYS_ICON_DIR=\"${SYS_ICON_DIR/$ROOT_DIR/}\"" >> $SF
# 	echo "SYS_THEM_DIR=\"${SYS_THEM_DIR/$ROOT_DIR/}\"" >> $SF
# 	echo "INSTALL_WINE=\"$INSTALL_WINE\"" >> $SF
# 	echo "SYS_WINF_DIR=\"$SYS_WINF_DIR\"" >> $SF
# 	echo "optF=\"${optF/$ROOT_DIR/}\"" >> $SF
# 	echo "INSTALL_SKEL=\"$INSTALL_SKEL\"" >> $SF
# 	echo "INSTALL_TDM=\"$INSTALL_TDM\"" >> $SF
# 	echo "WINF_USERS=\"$WINF_USERS\"" >> $SF
# 	echo "OS_TYPE=\"$OS_TYPE\"" >> $SF
# 
# 	cp $SF "$SYS_WINF_DIR/winfinity-vars"
# fi


# ensure read and execute are set for regular users for files in system winfinity directory
if [[ "$INSTALL_SYS" == "1" && "$wSu" == "1" ]]
then
	chmod -R a+rX $SYS_WINF_DIR
fi

# message
if [[ "$WINF_SILENT" != "1" ]]
then
  echo "Winfinity Install Complete!"
  echo " "
  echo "Please reboot your computer. If you are in a text shell, run 'sudo reboot'."
  echo " "
fi