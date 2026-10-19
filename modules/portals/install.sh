#!/bin/bash

source $VARS

PTL="$HOME_DIR/.config/xdg-desktop-portal"
TENV="$HOME_DIR/.trinity/env"

mkdir -p "$PTL"
mkdir -p "$TENV"

cp "$mD/files/portals.conf" "$PTL/portals.conf"
cp "$mD/files/TDE-portals.conf" "$PTL/TDE-portals.conf"
cp "$mD/files/xdg-portals.sh" "$TENV/xdg-portals.sh"

