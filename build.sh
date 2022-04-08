#!/usr/bin/env bash

#
#   Script to build archnemo iso
#

# Get current working directory
currWD=$(pwd)
rootD=$currWD/airootfs/root

# Cleaning previous build (if there were any)
echo "Cleaning up..."
[[ -d out ]] && rm -fr out
[[ -d work ]] && rm -fr work
echo "Cleanup complete!"

echo "Preparing custom repo..."
[[ ! -d /tmp/blankdb ]] && mkdir /tmp/blankdb
pacman -Syw --cachedir airootfs/usr/local/repo --dbpath /tmp/blankdb --noconfirm --needed - < airootfs/root/packages.x86_64
[[ -f airootfs/usr/local/repo/custom.db.tar.gz ]] && rm -fr airootfs/usr/local/repo/custom*
repo-add ./airootfs/usr/local/repo/custom.db.tar.gz ./airootfs/usr/local/repo/*.zst
repo-add ./airootfs/usr/local/repo/custom.db.tar.gz ./airootfs/usr/local/repo/*.xz
repo-add ./airootfs/usr/local/repo/custom.db.tar.gz ./airootfs/usr/local/repo/*.gz
echo "Custom repo is up to date!"

# Preparing custom configuration files (dotfiles)
echo "Preparing custom configuration files..."
cd $rootD
[[ ! -d .dotfiles ]] \
  && git clone https://github.com/nemo256/.dotfiles
[[ ! -d Documents ]] \
  && git clone https://github.com/nemo256/Documents
[[ ! -d Pictures ]] \
  && git clone https://github.com/nemo256/Pictures
[[ ! -d Music ]] \
  && git clone https://github.com/nemo256/Music

# Preparing dwm, st, dmenu...
[[ ! -d .build ]] && mkdir .build
cd .build
[[ ! -d dwm ]] \
  && git clone https://github.com/nemo256/dwm
[[ ! -d st ]] \
  && git clone https://github.com/nemo256/st
[[ ! -d dmenu ]] \
  && git clone https://github.com/nemo256/dmenu
[[ ! -d slstatus ]] \
  && git clone https://github.com/nemo256/slstatus
[[ ! -d slock ]] \
  && git clone https://github.com/nemo256/slock
[[ ! -d ani-cli ]] \
  && git clone https://github.com/pystardust/ani-cli
[[ ! -d tty-clock ]] \
  && git clone https://github.com/xorg62/tty-clock
[[ ! -d grabc ]] \
  && git clone https://github.com/muquit/grabc
[[ ! -d tremc ]] \
  && git clone https://github.com/tremc/tremc
cd $rootD

# Pulling latest versions
cd .dotfiles && git pull
cd ../Documents && git pull
cd ../Pictures && git pull
cd ../Music && git pull
cd ../.build/dwm && git pull
cd ../st && git pull
cd ../dmenu && git pull
cd ../slstatus && git pull
cd ../slock && git pull
cd ../ani-cli && git pull
cd ../abook && git pull
cd ../grabc && git pull
cd ../tremc && git pull
echo "Custom configuration files are up to date!"

# Go back to project directory
cd $currWD

# .env template file
echo "Preparing custom configuration files..."
[[ ! -f airootfs/root/.env ]] && echo -ne '
USERNAME=root
PASSWORD=
HOSTNAME=macbook
SHELL=/bin/bash
TOKEN=
DISK=/dev/sda
MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
FS=ext4
TIMEZONE=Africa/Algiers
KEYMAP=us
' > airootfs/root/.env

# Start building the iso
mkarchiso -v .
