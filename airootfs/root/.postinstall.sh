#!/usr/bin/env bash

################################################
#                                              #
# Create a .env file containing these options: #
#                                              #
################################################
#
# USERNAME=<New user name>
# PASSWORD=<New user password>
# HOSTNAME=<Hostname eg: macbook>
# SHELL=<eg: /bin/bash>
# TOKEN=<Your Github token (PAT)>
# DISK=<eg: /dev/sda>
# MOUNT_OPTIONS=<eg for ssd add: "noatime,ssd,...">
# FS=<Filesystem eg: ext4, btrfs...>
# TIMEZONE=<eg: Europe/Paris>
# KEYMAP=<eg: us,uk,es...>

source /root/.env

# Logo
clear
echo -ne "
------------------------------------------------------------------------------------------
          ░█████╗░██████╗░░█████╗░██╗░░██╗  ███╗░░██╗███████╗███╗░░░███╗░█████╗░
          ██╔══██╗██╔══██╗██╔══██╗██║░░██║  ████╗░██║██╔════╝████╗░████║██╔══██╗
          ███████║██████╔╝██║░░╚═╝███████║  ██╔██╗██║█████╗░░██╔████╔██║██║░░██║
          ██╔══██║██╔══██╗██║░░██╗██╔══██║  ██║╚████║██╔══╝░░██║╚██╔╝██║██║░░██║
          ██║░░██║██║░░██║╚█████╔╝██║░░██║  ██║░╚███║███████╗██║░╚═╝░██║╚█████╔╝
          ╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝  ╚═╝░░╚══╝╚══════╝╚═╝░░░░░╚═╝░╚════╝░
------------------------------------------------------------------------------------------
                              Arch Nemo Post Installation
------------------------------------------------------------------------------------------

"

echo -ne "
------------------------------------------------------------------------------------------
                                     Network Setup
------------------------------------------------------------------------------------------
"
# cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
# reflector -a 48 -c France,Germany -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
# mkdir /mnt &>/dev/null # hiding error message if any

echo -ne "
------------------------------------------------------------------------------------------
                                Setup Language And Locale
------------------------------------------------------------------------------------------
"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone ${TIMEZONE}
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
# Set keymaps
localectl --no-ask-password set-keymap ${KEYMAP}

# Add sudo no password rights
# sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo -ne "
------------------------------------------------------------------------------------------
                                     Adding User
------------------------------------------------------------------------------------------
"
# useradd -m -G wheel,libvirt -s $SHELL $USERNAME 
# echo "$USERNAME created, home directory created, added to wheel and libvirt group, default shell set to /bin/bash"

pwconv
echo "${USERNAME}:${PASSWORD}" | chpasswd
echo "${HOSTNAME}" > /etc/hostname

echo -ne "
------------------------------------------------------------------------------------------
                                 Creating GRUB Boot Menu
------------------------------------------------------------------------------------------
"
# Installing GRUB
if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK} --recheck --force
fi

# Optimize grub for macbook air and skip through it (I don't multiboot)
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& rootflags=data=writeback libata.force=1:noncq/' /etc/default/grub
sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
sed -i 's/^#GRUB_DISABLE_SUBMENU=y/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub

# Updating grub
echo -e "Updating grub..."
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"

echo -ne "
------------------------------------------------------------------------------------------
                               Managing Essential Services
------------------------------------------------------------------------------------------
"
systemctl disable --now transmission.service
echo "--> Transmission disabled"
# systemctl disable dhcpcd.service
# echo "  DHCP disabled"
# systemctl stop dhcpcd.service
# echo "  DHCP stopped"
systemctl enable NetworkManager.service
echo "--> NetworkManager enabled"

echo -ne "
------------------------------------------------------------------------------------------
                              Changing Default Console Font
------------------------------------------------------------------------------------------
"
echo -ne 'KEYMAP="us"
FONT="ter-v32b"
' > /etc/vconsole.conf

echo -ne "
------------------------------------------------------------------------------------------
                                   Github Configuration      
------------------------------------------------------------------------------------------
"
# Adding the credentials file
echo -ne "https://nemo256:${TOKEN}@github.com" > ${HOME}/.git-credentials

echo -ne "
------------------------------------------------------------------------------------------
                                Installing Dwm, St, Dmenu...
------------------------------------------------------------------------------------------
"
# Change directory to where the build files are
cd /root/.build
# Building and installing using make
cd dwm && make clean install
cd ../st && make clean install
cd ../dmenu && make clean install
cd ../slock && make clean install
cd ../slstatus && make clean install
cd ../grabc && make && make install
cd ../tremc && make install
yarn global add @aweary/alder
yarn global add weather-cli

echo -ne "
------------------------------------------------------------------------------------------
                                 Restoring Home Directory
------------------------------------------------------------------------------------------
"
cd $HOME && mkdir downloads videos music work
cd $HOME

echo -ne "
------------------------------------------------------------------------------------------
                                Stowing Configuration Files
------------------------------------------------------------------------------------------
"
# Removing default files
rm -fvr ${HOME}/.bash*
rm -fvr ${HOME}/.gitconfig
rm -fvr ${HOME}/.config/*

# Dotfiles directory
cd $HOME/.dotfiles

# Stowing configuration files
stow abook
stow alsa
stow bin
stow bash
stow dunst
stow git
stow gtk-2.0
stow gtk-3.0
stow htop
stow irssi
stow mbsync
stow mimeapps
stow mpd
stow mpv
stow mutt
stow ncmpcpp
stow neofetch
stow newsboat
stow notmuch
stow nvim
stow ranger
stow transmission-daemon
stow tremc
stow weather-cli-nodejs
stow xinit
stow yarn
stow zathura

# Making bin files executable
chmod -R 755 $HOME/bin

echo -ne "
------------------------------------------------------------------------------------------
                                   Neovim Configuration
------------------------------------------------------------------------------------------
"
# Adding vim-plug
curl -fLo ${HOME}/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Installing neovim plugins
nvim -c 'PlugInstall | q! | q!'

echo -ne "
------------------------------------------------------------------------------------------
                                   Ranger Configuration
------------------------------------------------------------------------------------------
"
# Adding devicons to ranger
git clone https://github.com/alexanderjeurissen/ranger_devicons \
  ~/.config/ranger/plugins/ranger_devicons

echo -ne "
------------------------------------------------------------------------------------------
                                   Firefox Configuration
------------------------------------------------------------------------------------------
"
# To generate config folder
firefox

# Saving path to prefs.js file
prefs=$(find $HOME/.mozilla/ -name '*prefs.js')

# Adding magnet link support
echo -ne '
user_pref("network.protocol-handler.expose.magnet", false);
' >> $prefs

echo -ne "
------------------------------------------------------------------------------------------
                                    Fonts Configuration
------------------------------------------------------------------------------------------
"
# Adding nerd font (Droid Sans Mono)
# mkdir -p ${HOME}/.fonts
# cd ${HOME}/.fonts && curl -fLo "Fira Code Bold Nerd Font Complete.ttf" https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/FiraCode/Bold/complete/Fira%20Code%20Bold%20Nerd%20Font%20Complete.ttf

# Update fonts
# fc-cache -f -v

# Return back to home directory
# cd $HOME

echo -ne "
------------------------------------------------------------------------------------------
                                    Slock Configuration
------------------------------------------------------------------------------------------
"
# Adding slock service
echo -ne '[Unit]
Description=Lock X session using slock for user %i
Before=sleep.target

[Service]
User=%i
Environment=DISPLAY=:0
ExecStartPre=/usr/bin/xset dpms force suspend
ExecStart=/usr/local/bin/slock

[Install]
WantedBy=sleep.target
' > /etc/systemd/system/slock@.service

echo -ne "
------------------------------------------------------------------------------------------
                               Updating Touchpad Configuration
------------------------------------------------------------------------------------------
"
# Touchpad configuration
echo -ne 'Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Option "Tapping" "True"
    Option "TappingDrag" "True"
    Option "ScrollMethod" "Twofinger"
    Option "NaturalScrolling" "False"
    Option "DisableWhileTyping" "False"
    Driver "libinput"
EndSection
' > /etc/X11/xorg.conf.d/40-libinput.conf

echo -ne "
------------------------------------------------------------------------------------------
                               Re-enabling Essential Services
------------------------------------------------------------------------------------------
"
# Enabling slock to lock screen on suspend / sleep
systemctl enable slock@$(whoami).service
echo "  Slock enabled!"

echo -ne "
------------------------------------------------------------------------------------------
                                         Cleaning
------------------------------------------------------------------------------------------
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

rm -fvr $HOME/.postinstall.sh $HOME/.env

echo -ne "
------------------------------------------------------------------------------------------
          ░█████╗░██████╗░░█████╗░██╗░░██╗  ███╗░░██╗███████╗███╗░░░███╗░█████╗░
          ██╔══██╗██╔══██╗██╔══██╗██║░░██║  ████╗░██║██╔════╝████╗░████║██╔══██╗
          ███████║██████╔╝██║░░╚═╝███████║  ██╔██╗██║█████╗░░██╔████╔██║██║░░██║
          ██╔══██║██╔══██╗██║░░██╗██╔══██║  ██║╚████║██╔══╝░░██║╚██╔╝██║██║░░██║
          ██║░░██║██║░░██║╚█████╔╝██║░░██║  ██║░╚███║███████╗██║░╚═╝░██║╚█████╔╝
          ╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝  ╚═╝░░╚══╝╚══════╝╚═╝░░░░░╚═╝░╚════╝░
------------------------------------------------------------------------------------------
                              Automated Arch Nemo Installer
------------------------------------------------------------------------------------------
                            Done - Please Eject Install Media

"
