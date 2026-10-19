#!/bin/bash
source "$VARS"


# Winfinity share files module installer
# must be run from within winfinity install system

mkdir -p "$HOME_DIR/.trinity/share"
rsync -a --chmod=u=rwX,go=rX "$mD/share/" "$HOME_DIR/.trinity/share/"
cp "$mD/.fonts.conf" "$HOME_DIR/.fonts.conf"

# enable icons for home/Documents, etc
echo "while IFS='=' read -r key val; do [[ \"\$key\" =~ XDG_.*_DIR ]] && [[ \"\$key\" != *DESKTOP* ]] && dir=\$(eval echo \"\$val\") && [[ -d \"\$dir\" ]] && tmp=\${key#XDG_} && name=\${tmp%_DIR} && raw_icon=\"folder-\${name,,}\" && icon=\"\${raw_icon%s}\" && printf \"[Desktop Entry]\\\nIcon=%s\\\n\" \"\$icon\" > \"\$dir/.directory\"; done < \"\$HOME/.config/user-dirs.dirs\"" >> $WINF_FIRSTRUN

