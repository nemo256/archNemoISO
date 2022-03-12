#!/usr/bin/env bash

#
#   Script to build archnemo iso
#

# Get current working directory
currWD=$(pwd)
rootD=$currWD/airootfs/root

# Cleaning previous build (if there were any)
echo "Cleaning up..."
[[ -d out ]] && rm -fvr out
[[ -d work ]] && rm -fvr work
echo "Cleanup complete!"

# Preparing custom configuration files (dotfiles)
cd $rootD
[[ ! -d .dotfiles ]] \
  && git clone https://github.com/nemo256/.dotfiles

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
[[ ! -d abook ]] \
  && git clone https://github.com/hhirsch/abook
[[ ! -d grabc ]] \
  && git clone https://github.com/muquit/grabc
[[ ! -d tremc ]] \
  && git clone https://github.com/tremc/tremc
cd $rootD

# Pulling latest versions
cd .dotfiles && git pull
cd ../.build/dwm && git pull
cd ../st && git pull
cd ../dmenu && git pull
cd ../slstatus && git pull
cd ../slock && git pull
cd ../abook && git pull
cd ../grabc && git pull
cd ../tremc && git pull

# Go back to project directory
cd $currWD

# start building the iso
mkarchiso -v .
