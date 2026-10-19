#!/bin/bash
source "$VARS"

# Winfinity Propriatary Resource Pack
#
# Must be run from within module installer enviornment

#set -x

# only run if prop enabled
if [[ "$TDE_PROP" == "1" ]]
then

# determine whether system or user install
if [[ "$INSTALL_SYS" == "1" ]]
then
	# specify prop version file
	echo "1.0" > "$sD/PROP-VERSION"
	
	# use system wide directories
	FONT_INSTALL_DIR="$SYS_FONT_DIR"
	ICON_INSTALL_DIR="$SYS_ICON_DIR"
	WINF_FONTS="1"
	TDE_INSTALL_PREFIX="$TDE_SYS_DIR"
else
	# use home directories
	FONT_INSTALL_DIR="$HOME_DIR/.local/share/fonts"
	WINF_FONTS="1"
	ICON_INSTALL_DIR="$HOME_DIR/.local/share/icons"
	TDE_INSTALL_PREFIX="$HOME_DIR/.trinity"
fi

mkdir -p "$FONT_INSTALL_DIR"
cp -p $mD/fonts/*.ttf "$FONT_INSTALL_DIR" #source paramter not quoted due to wildcard

mkdir -p "$ICON_INSTALL_DIR"
cp -rp "$mD/winicons/wincursors-classic" "$ICON_INSTALL_DIR"
#update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme \
#    /usr/share/icons/wincursors-classic/index.theme 100

#cp -rp "$mD/winicons/gtk-icons-9x" "$ICON_INSTALL_DIR/Winfinity-classic-gtk"
rsync -a --chmod=u=rwX,go=rX "$mD/winicons/Winfinity-Classic" "$ICON_INSTALL_DIR/"

# refresh font cache if enabled
if [[ "$WINF_FONTS" == "1" ]]
then
	fc-cache -f -v > /dev/null 2>&1
fi

mkdir -p "$TDE_INSTALL_PREFIX"
cp -rp "$mD/tde-root/resources/share" "$TDE_INSTALL_PREFIX"
#cp -r "$mD/winicons/Winfinity-Classic" "$TDE_INSTALL_PREFIX/share/icons/"
#rsync -a --chmod=u=rwX,go=rX "$mD/winicons/Winfinity-Classic" "$TDE_INSTALL_PREFIX/share/icons/"

### $TDE_PROP
fi