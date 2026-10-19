#!/bin/bash
# Winfinity WINE Installer
# Debian 13 (Trixie)
# installs wine and winetricks, does not configure
# Run as root or with sudo
# uses WineHQ repository and GitHub winetricks

# Add repository and install Wine
mkdir -pm755 /etc/apt/keyrings
wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
dpkg --add-architecture i386
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources
apt-get update
apt-get -y install --install-recommends winehq-stable cabextract exe-thumbnailer

#
#  Winetricks
#  Modified from Winetricks GitHub update script
#

# Create and switch to a temporary directory writeable by current user. 
pushd "$(mktemp -d)" || exit 1

###### create update_winetricks START ########
cat > update_winetricks <<_EOF_SCRIPT
#!/bin/sh
# must be run with root or sudo
# Debian 13 (Trixie)

# Create and switch to a temporary directory writeable by current user.
pushd "\$(mktemp -d)"

wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks

chmod +x winetricks

# Move the winetricks script to a location which will be in the standard user PATH. See:
mv winetricks /usr/bin

# Download the latest winetricks BASH completion script
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion

# Move the winetricks BASH completion script to a standard location for BASH completion modules.
mv winetricks.bash-completion /usr/share/bash-completion/cormpletions/winetricks

# Download the latest winetricks MAN page (master="latest version") from Github.
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.1

# Move the winetricks MAN page to a standard location for MAN pages.
sudo mv winetricks.1 /usr/share/man/man1/winetricks.1
popd
_EOF_SCRIPT
###### create update_winetricks FINISH ########

chmod +x update_winetricks

mv update_winetricks /usr/bin/

/usr/bin/update_winetricks


popd