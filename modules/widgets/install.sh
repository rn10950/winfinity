#!/bin/bash
source "$VARS"

# Winfinity widget installer
#
# Must be run from within module installer enviornment

mkdir -p $HOME_DIR/.themes/
rsync -a --chmod=u=rwX,go=rX "$mD/gtk-theme/theme/Redmond9x" $HOME_DIR/.themes/

mkdir -p $HOME_DIR/.config

# install profile files
cp -r "$mD/qt-theme/qt5ct" $HOME_DIR/.config/
cp -r "$mD/qt-theme/qt6ct" $HOME_DIR/.config/


gS="$mD/gtk-theme"

cp "$gS/profile/.gtkrc-2.0" "$HOME_DIR/.gtkrc-2.0"
cp -r "$gS/profile/.config" "$HOME_DIR"
