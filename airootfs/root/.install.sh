#!/usr/bin/env bash

# Set a bold custom terminus font
setfont ter-v32b

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
                              Automated Arch Linux Installer
------------------------------------------------------------------------------------------

"

echo -ne "
                               Press any key to continue...
"

# Setup configuration
USERNAME=root
NAME_OF_MACHINE=macbook
DISK=/dev/sda
MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
FS=ext4
TIMEZONE=Africa/Algiers
KEYMAP=us

echo -ne "
------------------------------------------------------------------------------------------
                                  Setting Up Mirrors
------------------------------------------------------------------------------------------
"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -a 48 -c France,Germany -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null # Hiding error message if any

echo -ne "
------------------------------------------------------------------------------------------
                                   Formating Disks
------------------------------------------------------------------------------------------
"
umount -A --recursive /mnt # make sure everything is unmounted before we start
# Disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# Create partitions
sgdisk -n 1::+128M --typecode=1:af00 --change-name=1:'Boot Loader' ${DISK} # partition 1 (Boot loader Partition)
sgdisk -n 2::+256M --typecode=2:8300 --change-name=2:'Boot' ${DISK} # partition 2 (Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'Root' ${DISK} # partition 3 (Root), default start, remaining space

if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 ${DISK}
fi
partprobe ${DISK} # reread partition table to ensure it is correct

# Make filesystems
echo -ne "
------------------------------------------------------------------------------------------
                                  Creating Filesystems
------------------------------------------------------------------------------------------
"
partition2=${DISK}2
partition3=${DISK}3

mkfs.fat -F32 ${partition2}
mkfs.ext4 -L Root ${partition3}
mount -t ext4 ${partition3} /mnt

# Mount target
mkdir /mnt/boot
mount ${partition2} /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted, can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi

echo -ne "
------------------------------------------------------------------------------------------
                                    Arch installation
------------------------------------------------------------------------------------------
"
while read line
do
  echo "Pacstraping: ${line}"
  sudo pacstrap /mnt ${line}
done < packages.x86_64

genfstab -L /mnt >> /mnt/etc/fstab
echo " 
  Generated /etc/fstab:
"
cat /mnt/etc/fstab

echo -ne "
------------------------------------------------------------------------------------------
                          GRUB BIOS Bootloader Install And Check
------------------------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
    echo "Installed bootloader for BIOS!"
else
    echo "Skipping (UEFI)!"
fi
echo -ne "
------------------------------------------------------------------------------------------
                           Checking For Low Memory Systems <8Gb
------------------------------------------------------------------------------------------
"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir -p /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab # add swap to fstab, so it KEEPS working after installation.
fi

echo -ne "
------------------------------------------------------------------------------------------
                                     Network Setup
------------------------------------------------------------------------------------------
"
arch-chroot /mnt ping -c 3 google.com

echo -ne "
------------------------------------------------------------------------------------------
                                Setup Language And Locale
------------------------------------------------------------------------------------------
"
arch-chroot /mnt sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt timedatectl --no-ask-password set-timezone ${TIMEZONE}
arch-chroot /mnt timedatectl --no-ask-password set-ntp 1
arch-chroot /mnt localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
arch-chroot /mnt ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
# Set keymaps
arch-chroot /mnt localectl --no-ask-password set-keymap ${KEYMAP}

# Add sudo no password rights
arch-chroot /mnt sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
arch-chroot /mnt sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Add parallel downloading
arch-chroot /mnt sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Enable multilib
arch-chroot /mnt sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
arch-chroot /mnt pacman -Sy --noconfirm --needed

echo -ne "
------------------------------------------------------------------------------------------
                                     Adding User
------------------------------------------------------------------------------------------
"
arch-chroot /mnt chpasswd <<< "${USERNAME}:${PASSWORD}"
echo "${NAME_OF_MACHINE}" > /mnt/etc/hostname

if [[ -d "/sys/firmware/efi" ]]; then
    arch-chroot /mnt grub-install --efi-directory=/boot ${DISK} --recheck
fi

echo -ne "
------------------------------------------------------------------------------------------
                                 Creating GRUB Boot Menu
------------------------------------------------------------------------------------------
"
# Optimize grub for macbook air and skip through it (I don't multiboot)
arch-chroot /mnt sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& rootflags=data=writeback libata.force=1:noncq/' /etc/default/grub
arch-chroot /mnt sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
arch-chroot /mnt sed -i 's/^#GRUB_DISABLE_SUBMENU=y/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub

# Updating grub
echo -e "Updating grub..."
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"

echo -ne "
------------------------------------------------------------------------------------------
                               Managing Essential Services
------------------------------------------------------------------------------------------
"
arch-chroot /mnt systemctl disable --now transmission.service
echo "  Transmission disabled"
# arch-chroot /mnt systemctl disable dhcpcd.service
# echo "  DHCP disabled"
# arch-chroot /mnt systemctl stop dhcpcd.service
# echo "  DHCP stopped"
# arch-chroot /mnt systemctl enable NetworkManager.service
# echo "  NetworkManager enabled"

echo -ne "
------------------------------------------------------------------------------------------
                              Changing Default Console Font
------------------------------------------------------------------------------------------
"
echo -ne 'KEYMAP="us"
FONT="ter-v32b"
' > /mnt/etc/vconsole.conf

echo -ne "
------------------------------------------------------------------------------------------
                                   Github Configuration      
------------------------------------------------------------------------------------------
"
# Adding the credentials file
echo -ne "https://nemo256:${TOKEN}@github.com" > /mnt/${USERNAME}/.git-credentials

echo -ne "
------------------------------------------------------------------------------------------
                                Installing Dwm, St, Dmenu...
------------------------------------------------------------------------------------------
"
# Building and installing using make
arch-chroot /mnt cd .build/dwm && make clean install
arch-chroot /mnt cd ../st && make clean install
arch-chroot /mnt cd ../dmenu && make clean install
arch-chroot /mnt cd ../slock && make clean install
arch-chroot /mnt cd ../slstatus && make clean install
arch-chroot /mnt cd ../grabc && make && make install
arch-chroot /mnt cd ../tremc && make install
arch-chroot /mnt yarn global add @aweary/alder
arch-chroot /mnt yarn global add weather-cli

echo -ne "
------------------------------------------------------------------------------------------
                                Stowing Configuration Files
------------------------------------------------------------------------------------------
"
# Removing default files
rm -fvr /mnt/${USERNAME}/.bash*
rm -fvr /mnt/${USERNAME}/.gitconfig
rm -fvr /mnt/${USERNAME}/.config/*

# Dotfiles directory
arch-chroot /mnt cd $HOME/.dotfiles

# Stowing configuration files
arch-chroot /mnt stow abook
arch-chroot /mnt stow alsa
arch-chroot /mnt stow bin
arch-chroot /mnt stow bash
arch-chroot /mnt stow dunst
arch-chroot /mnt stow git
arch-chroot /mnt stow gtk-2.0
arch-chroot /mnt stow gtk-3.0
arch-chroot /mnt stow htop
arch-chroot /mnt stow irssi
arch-chroot /mnt stow mbsync
arch-chroot /mnt stow mimeapps
arch-chroot /mnt stow mpd
arch-chroot /mnt stow mpv
arch-chroot /mnt stow mutt
arch-chroot /mnt stow ncmpcpp
arch-chroot /mnt stow neofetch
arch-chroot /mnt stow newsboat
arch-chroot /mnt stow notmuch
arch-chroot /mnt stow nvim
arch-chroot /mnt stow ranger
arch-chroot /mnt stow transmission-daemon
arch-chroot /mnt stow tremc
arch-chroot /mnt stow weather-cli-nodejs
arch-chroot /mnt stow xinit
arch-chroot /mnt stow yarn
arch-chroot /mnt stow zathura

echo -ne "
------------------------------------------------------------------------------------------
                                   Neovim Configuration
------------------------------------------------------------------------------------------
"
# Adding vim-plug
curl -fLo /mnt/${USERNAME}/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Installing neovim plugins
arch-chroot /mnt nvim -c 'PlugInstall | q! | q!'

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
# Saving path to prefs.js file
# prefs=$(find /mnt/${USERNAME}/.mozilla/ -name '*prefs.js')

# Adding magnet link support
# echo -ne '
# user_pref("network.protocol-handler.expose.magnet", false);
# ' >> $prefs

echo -ne "
------------------------------------------------------------------------------------------
                                    Fonts Configuration
------------------------------------------------------------------------------------------
"
# Adding nerd font (Droid Sans Mono)
# mkdir -p /mnt/${USERNAME}/.fonts
# cd /mnt/${USERNAME}/.fonts && curl -fLo "Fira Code Bold Nerd Font Complete.ttf" https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/FiraCode/Bold/complete/Fira%20Code%20Bold%20Nerd%20Font%20Complete.ttf

# Update fonts
# arch-chroot /mnt fc-cache -f -v

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
' > /mnt/etc/systemd/system/slock@.service

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
' > /mnt/etc/X11/xorg.conf.d/40-libinput.conf

echo -ne "
------------------------------------------------------------------------------------------
                               Re-enabling Essential Services
------------------------------------------------------------------------------------------
"
# Enabling slock to lock screen on suspend / sleep
arch-chroot /mnt systemctl enable slock@$(whoami).service
echo "  Slock enabled!"

echo -ne "
------------------------------------------------------------------------------------------
                                         Cleaning
------------------------------------------------------------------------------------------
"
