#!/bin/bash
#Debian 13 "Trixie" Only
#run as root or with sudo
#script will enable contrib and non-free repositories
#set WINF_POSTINSTALL to the path of a script to run after main package install


WINF_DISABLE_WINE="1"


function interPrompt {
	echo "Interactive shell: when done, type 'exit' to return to installation"
	bash
}

function pause {
	read -rsp $'Press enter to continue...\n'
}

set -x

# allow custom temporary directory (helps preserve settings over reboots during testing)
if [[ -z $TMPDIR ]]
then
	TMPDIR="/var/tmp"
fi


#apt retry
for i in "$@" ; do
    if [[ $i == "APT_RETRY" ]] ; then
        echo 'APT::Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries
		sleep 2
        break
    fi
done


# load variables if passed
if [[ -v $VARS ]]
then
	source $VARS
fi


# allow verbose output
if [[ -z $winfinityVerbose ]]
then
	winfinityVerbose="0"
fi


# check to see if running in source directory or if directory flag passed
if [[ -z $WINFINITY_SOURCE_DIR ]]
then
	if [[ -f "./winfinity.txt" ]]
	then
		wS="$PWD"
	else
		echo "Winfinity Installer must be run from the Winfinity source directory." 
		return 1
		exit 1
	fi
else
	wS="$WINFINITY_SOURCE_DIR"
fi

# ==================================
#  Define distro specific variables
# ==================================
OS_TYPE="debian13"
PREFIX_DIR="$TMPDIR/winfinity-fs"
ROOT_DIR="$PREFIX_DIR/root"
HOME_DIR="$PREFIX_DIR/home"
SYS_WINF_DIR="/opt/winfinity"
TDE_SYS_DIR="$ROOT_DIR/opt/trinity"
SYS_FONT_DIR="$ROOT_DIR/usr/local/share/fonts"
SYS_ICON_DIR="$ROOT_DIR/usr/share/icons"
SYS_THEM_DIR="$ROOT_DIR/usr/share/themes"
sD="$ROOT_DIR/opt/winfinity"
optF="$sD/optional-features"

# Default INSTALL_SYS to on for Debian install
INSTALL_SYS="1"

WINF_VERSION=$(< "$wS/version.txt")

mkdir -p $sD
mkdir -p $HOME_DIR
touch $optF
echo "$WINF_VERSION" > $sD/VERSION


# installer temporary files
tD="$TMPDIR/winfinity-temp"
mkdir $tD

# create autorun scripts
WINF_FIRSTRUN="$tD/firstrun.sh"
WINF_AUTOEXEC="$tD/autoexec.sh"
for scr in "$WINF_FIRSTRUN" "$WINF_AUTOEXEC"; do
	echo '#!/bin/bash' > $scr
	echo "source $SYS_WINF_DIR/winfinity-vars" >> $scr
	chmod a+x $scr
done


# install dependencies for installer
apt-get update
apt-get -y install dialog curl rsync


# ==============
#  Set up users
# ==============
if [[ -z $WINF_USERS ]]
then
TMP_USERS=$(mktemp)
>$TMP_USERS
dialog --title "Enter Users" \
--backtitle "Winfinity Installer" \
--inputbox "Enter the user names for which you would like to to install Winfinity. \n\n\
Multiple users may be separated by a comma without a space. \n\
EX: tom,dick,harry \n \n\
Users must already exist. \n\n" 14 80 2>$TMP_USERS
respose=$?
WINF_USERS=$(<$TMP_USERS)
fi


# =============================
#  Prompt User for preferences
# =============================

# proprietary resources
if [[ -z $TDE_PROP ]]
then
	dialog --title "Install Proprietary Resources?" \
	--backtitle "Winfinity Installer" \
	--yesno "Do you want to install proprietary resources, such as icons, fonts and sounds?" 15 60
	response=$?
	case $response in
	   0)
		TDE_PROP="1"
		;;
	   1)TDE_PROP="0" ;;
	   255)TDE_PROP="0";;
	esac
fi
[[ "$TDE_PROP" == "1" ]] && echo "prop" >> $optF


# boot to GUI (display manager)
if [[ -z $INSTALL_TDM ]]
then
	dialog --title "Boot to GUI?" \
	--backtitle "Winfinity Installer" \
	--yesno "Do you want to automatically boot into Winfinity? \
	This will start the X server automatically on boot. Disabling this option \
	will cause your computer to boot into a text console, where you can then log in \
	and start Winfinity manually." 15 60
	response=$?
	case $response in
	  0) INSTALL_TDM="1";;
	  1) INSTALL_TDM="0";;
	  255) INSTALL_TDM="1";;
	esac
fi


# install boot splash
if [[ -z $INSTALL_BOOT_SPLASH ]]
then
	if [[ "$TDE_PROP" == "1" ]]
	then
		# install boot splash
		dialog --title "Install Boot Splash?" \
		--backtitle "Winfinity Installer" \
		--yesno "Do you want to install Plymouth and the Winfinity boot splash?" 15 60
		response=$?
		case $response in
		   0)#install splash
				INSTALL_BOOT_SPLASH="1"
				;;
		   1)
				INSTALL_BOOT_SPLASH="0"
				;;
		   255)
				INSTALL_BOOT_SPLASH="1"
				;;
		esac
	else
		INSTALL_BOOT_SPLASH="0"
	fi
fi


# /etc/skel
if [[ -z $INSTALL_SKEL ]]
then
	dialog --title "Install Winfinity into /etc/skel?" \
	--backtitle "Winfinity Installer" --defaultno \
	--yesno "Do you want to install Winfinity into /etc/skel? This will copy the \
	Winfinity configuration files to every new user profile created after the change. \
	You might want to select this option if Winfinity is the only desktop environment \
	you plan to use on this computer. Do not select this option if you do not completely \
	understand what it does." 15 60
	response=$?
	case $response in
	   0)
		INSTALL_SKEL="1"
		;;
	   1)INSTALL_SKEL="0" ;;
	   255)INSTALL_SKEL="0";;
	esac
fi
[[ "$INSTALL_SKEL" == "1" ]] && echo "skel" >> $optF

#optional software
cmd=(dialog --separate-output --backtitle "Winfinity Installer" --checklist "Select software (space=select, enter=submit):" 22 76 16)
options=(1 "Mozilla Firefox" on
         2 "Palemoon Web Browser" off
         3 "Chromium" off
         4 "VLC Media Player" off
         5 "QMMP - Winamp clone" off
         6 "LibreOffice" off
         7 "Microsoft Core Fonts" on
         8 "PipeWire Audio (WirePlumber)" on
         9 "PulseAudio (depreciated: replaced by PipeWire)" off
         10 "Winfinity Dev Tools" off
         11 "Tux Manager - Win10-like Task Manager" off)
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
#clear
sTI=""
oS=$(mktemp)
for choice in $choices
do
    case $choice in
        1)
	    # use firefox ESR to delay monthly UX redesigns
	    INSTALL_FIREFOX="1"
	    sTI="$sTI firefox-esr"
	    echo "firefox-esr" >> $oS
            ;;
        2)
	    INSTALL_PALEMOON="1"
	    sTI="$sTI palemoon"
	    echo "palemoon veit-kannegieser-archive-keyring" >> $oS
            ;;
        3)
            sTI="$sTI chromium"
	    echo "chromium" >> $oS
            ;;
        4)
            sTI="$sTI vlc"
	    echo "vlc" >> $oS
            ;;
        5)
            sTI="$sTI qmmp"
	    echo "qmmp" >> $oS
            ;;
        6)
            sTI="$sTI libreoffice"
	    echo "libreoffice" >> $oS
            ;;
        7)
            sTI="$sTI ttf-mscorefonts-installer"
	    echo "ttf-mscorefonts-installer" >> $oS
            ;;
        8)
            sTI="$sTI pipewire-audio pavucontrol-qt"
	    echo "pipewire-audio" >> $oS
	    echo "pavucontrol-qt" >> $oS
            ;;
        9)
            sTI="$sTI pulseaudio pavucontrol-qt"
	    echo "pulseaudio" >> $oS
	    echo "pavucontrol-qt" >> $oS
            ;;
        10)
            #Winfinity dev tools
            WINF_DEV_TOOLS="1"
            sTI="$sTI"
            ;;
        11)
            #Tux Manager
            TUX_MANAGER="1"
            ;;
    esac
done

[[ -z $WINF_DEV_TOOLS ]] && WINF_DEV_TOOLS="0"

# firefox policies.json
if [[ -z $FIREFOX_POLICIES ]] && [[ "$INSTALL_FIREFOX" == "1" ]]
then
	dialog --title "Install Firefox Policies?" \
	--backtitle "Winfinity Installer" \
	--yesno "Do you want to install a policies.json file for Firefox?" 15 60
	response=$?
	case $response in
	   0)
		FIREFOX_POLICIES="1"
		;;
	   1)FIREFOX_POLICIES="0" ;;
	   255)FIREFOX_POLICIES="1";;
	esac
fi
[[ "$FIREFOX_POLICIES" == "1" ]] && echo "FIREFOX_POLICIES" >> $optF

# WINE (presently disabled, skip)
if [[ -z $INSTALL_WINE ]] && [[ "$WINF_DISABLE_WINE" != "1" ]]
then
	dialog --title "Install WINE?" \
	--backtitle "Winfinity Installer" --defaultno \
	--yesno "Do you want to install WINE Windows program loader?" 15 60
	response=$?
	case $response in
	   0)
		INSTALL_WINE="1"
		;;
	   1)INSTALL_WINE="0" ;;
	   255)INSTALL_WINE="0";;
	esac
fi
[[ -z $INSTALL_WINE ]] && INSTALL_WINE="0"

# =================================================
#  save winfinity-source if bootstrap install used
# =================================================
if [[ "$WINF_BOOTSTRAP" == "1" ]]
then
	if [[ "$INSTALL_SYS" == "1" ]]
	then
		rsync -a --chmod=u=rwX,go=rX "$wS/" "$SYS_WINF_DIR/winfinity-source"
		wS="$SYS_WINF_DIR/winfinity-source"
	fi
fi


# =========================
#  Define install prefixes
# =========================
TDE_USER_INSTALL_PREFIX="$HOME_DIR/.trinity"
WINF_USER_INSTALL_PREFIX="$HOME_DIR/.winfinity"

# ======================
#  Write variables file
# ======================
SF="$TMPDIR/winfinity-installer-settings"
rm $SF
echo "TMPDIR=\"$TMPDIR\"" >> $SF
echo "TDE_SYS_DIR=\"$TDE_SYS_DIR\"" >> $SF
echo "SYS_FONT_DIR=\"$SYS_FONT_DIR\"" >> $SF
echo "SYS_ICON_DIR=\"$SYS_ICON_DIR\"" >> $SF
echo "SYS_THEM_DIR=\"$SYS_THEM_DIR\"" >> $SF
echo "sD=\"$sD\"" >> $SF
echo "optF=\"$optF\"" >> $SF
echo "PREFIX_DIR=\"$PREFIX_DIR\"" >> $SF
echo "SYS_WINF_DIR=\"$SYS_WINF_DIR\"" >> $SF
echo "WINFINITY_SOURCE_DIR=\"$wS\"" >> $SF
echo "ROOT_DIR=\"$ROOT_DIR\"" >> $SF
echo "HOME_DIR=\"$HOME_DIR\"" >> $SF
echo "INSTALL_SYS=\"$INSTALL_SYS\"" >> $SF
echo "INSTALL_SKEL=\"$INSTALL_SKEL\"" >> $SF
echo "INSTALL_TDM=\"$INSTALL_TDM\"" >> $SF
echo "INSTALL_WINE=\"$INSTALL_WINE\"" >> $SF
echo "TDE_PROP=\"$TDE_PROP\"" >> $SF
echo "WINF_FIRSTRUN=\"$WINF_FIRSTRUN\"" >> $SF
echo "WINF_AUTOEXEC=\"$WINF_AUTOEXEC\"" >> $SF
echo "WINF_USERS=\"$WINF_USERS\"" >> $SF
echo "OS_TYPE=\"$OS_TYPE\"" >> $SF
echo "TDE_INSTALL_PREFIX=\"$TDE_SYS_DIR\"" >> $SF
echo "WINF_INSTALL_PREFIX=\"$sD\"" >> $SF
echo "TDE_USER_INSTALL_PREFIX=\"$TDE_USER_INSTALL_PREFIX\"" >> $SF
echo "WINF_USER_INSTALL_PREFIX=\"$WINF_USER_INSTALL_PREFIX\"" >> $SF
echo "winfinityVerbose=\"$winfinityVerbose\"" >> $SF
echo "WINF_DEV_TOOLS=\"$WINF_DEV_TOOLS\"" >> $SF
cp $SF $sD


# ===============
#  Configure APT
# ===============

# Trinity
cat <<EOF | tee /etc/apt/sources.list.d/trinity.sources 
Types: deb  deb-src
URIs: http://mirror.ppa.trinitydesktop.org/trinity/deb/trinity-r14.1.x
Suites: trixie
Components: main deps
Signed-By: /usr/share/keyrings/trinity-archive-keyring.gpg
EOF

wget -P "$tD/" http://mirror.ppa.trinitydesktop.org/trinity/deb/trinity-keyring.deb
dpkg -i $tD/trinity-keyring.deb
rm $tD/trinity-keyring.deb


# Mozilla
if [[ "$INSTALL_FIREFOX" == "1" ]]
then
install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

cat <<EOF | tee /etc/apt/sources.list.d/mozilla.sources
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF

echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | tee /etc/apt/preferences.d/mozilla
fi


# Pale Moon
# apt-get -y install palemoon veit-kannegieser-archive-keyring
if [[ "$INSTALL_PALEMOON" == "1" ]]
then
cat <<EOF | tee /etc/apt/sources.list.d/palemoon.sources 
Types:              deb
URIs:               https://kannegieser.net/palemoon
Suites:             avx_gtk2
Architectures:      amd64
Components:         main
Signed-by:          /usr/share/keyrings/veit@kannegieser.net.pgp
EOF
wget https://kannegieser.net/palemoon/veit@kannegieser.net.pgp -O /usr/share/keyrings/veit@kannegieser.net.pgp
fi


# enable contrib and non-free
if [[ "$WINF_MANUAL_APT_SECTION_CONFIG" != "1" ]]
then
  sed -i 's/ main$/ main contrib non-free/g' /etc/apt/sources.list
  sed -i 's/ main / main contrib non-free /g' /etc/apt/sources.list
fi

# update
apt-get update


# ============================
#  Begin package installation
# ============================

# set package list
if [[ -z $pL ]]
then
    pL="$wS/packages/debian13/default.txt"
fi

# combine user selected software with software list
fPL=$(mktemp)
(cat $pL; echo; cat $oS) | grep -vE '^\s*#|^\s*$' | awk '!seen[$0]++' > $fPL

# install packages
grep -vE '^\s*#|^\s*$' $fPL | xargs apt-get install -y -f

# programbox code for apt-get example:
# apt-get -y -f install tdebase-trinity | dialog --programbox "Installing..." 40 70

# python dependencies for control-panel and install system
apt-get -y install python3-pytqt python3-pillow python3-yaml python3-dotenv



# =====================================================
#  Configure system options and install extra features
# =====================================================

if [[ "$INSTALL_TDM" == "0" ]]
then
	systemctl set-default multi-user.target
fi

# Boot splash (plymouth)
if [[ "$INSTALL_BOOT_SPLASH" == "1" ]]
then
  apt-get -y install plymouth plymouth-themes
  cp -rf "$wS/resources/splash/winfinity-boot" /usr/share/plymouth/themes
  chmod -R a+rX /usr/share/plymouth/themes/winfinity-boot
  update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/winfinity-boot/winfinity-boot.plymouth 100
  plymouth-set-default-theme winfinity-boot --rebuild-initrd
  echo "boot-splash" >> $optF
  
  # enable splash on grub kernel cmdline
  sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ {/splash/! s/"$/ splash"/; s/""/"splash"/}' /etc/default/grub
  update-grub
fi




# WINE
if [[ "$INSTALL_WINE" == 1 ]]
then
	$wS/scripts/debian13/wine-install.sh
	echo "wine" >> $optF
fi


# developer tools
if [[ "$WINF_DEV_TOOLS" == 1 ]]
then
	sD="$sD" $wS/scripts/debian13/devtools.sh
fi

# Tux Manager
if [[ "$TUX_MANAGER" == 1 ]]
then
  wget -O /var/tmp/tuxmanager.deb "https://github.com/benapetr/TuxManager/releases/download/v1.0.7/tux-manager_1.0.7-1.deb13_amd64.deb"
  apt-get -y install /var/tmp/tuxmanager.deb
fi

# Firefox policies
if [[ "$FIREFOX_POLICIES" == "1" ]]
then
  mkdir -p /etc/firefox/policies
  cp "$wS/resources/firefox-policies.json" /etc/firefox/policies/policies.json
  chmod -R a+rX /etc/firefox
fi

# =========================
#  Run user-defined script
# =========================
if [[ -n $WINF_POSTINSTALL ]]
then
  source "$WINF_POSTINSTALL"
fi


# =======================================
#  Install resources and set up profiles
# =======================================
pushd $wS
if [[ "$stageOneOnly" == "1" ]]
then
	echo "Stage 1 installation complete!"
else
	VARS="$SF" WINFINITY_SOURCE_DIR="$wS" $wS/winfinity-install.sh
fi
popd
