#!/bin/bash
# qt theme installation

gS="$wS/qt-theme"

echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> "$TDE_USERPROFILE/.bashrc"
cp -r "$gS/qt5ct" "$TDE_USERPROFILE/.config"
cp -r "$gS/qt6ct" "$TDE_USERPROFILE/.config"