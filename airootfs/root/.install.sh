#!/usr/bin/env bash

# Set a bold custom terminus font
setfont ter-v32b

################################################
#                                              #
# Create a .env file containing these options: #
#                                              #
################################################
#
# USERNAME=<New user name>
# PASSWORD=<New user password>
# HOSTNAME=<Hostname eg: macbook>
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
                              Automated Arch Nemo Installer
------------------------------------------------------------------------------------------

"

echo -ne "
                               Press any key to continue...
"
read

echo -ne "
------------------------------------------------------------------------------------------
                                  Setting Up Mirrors
------------------------------------------------------------------------------------------
"
pacman-key --init
pacman-key --populate
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -a 48 -c France,Germany -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null # hiding error message if any

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

if [[ ! -d "/sys/firmware/efi" ]]; then # checking for bios system
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
                         Arch-chrooting Into The New Installation
------------------------------------------------------------------------------------------
"
# Copy all configuration files
cp -fvr .build .dotfiles documents pictures /mnt/root
arch-chroot /mnt /root/.postinstall.sh
