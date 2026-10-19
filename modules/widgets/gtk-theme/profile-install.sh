#!/bin/bash
# gtk theme user profile setup

gS="$wS/gtk-theme"

#install profile files
cp "$gS/profile/.gtkrc-2.0-kde-kde4" "$TDE_USERPROFILE"
cp -r "$gS/profile/.config" "$TDE_USERPROFILE"
