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
                              Automated Arch Nemo Installer
------------------------------------------------------------------------------------------
"

echo -ne "
                               Press any key to continue...
"
read

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

# This is a better approache because it doesnt have to update everytime!
echo "Pacstraping... "
pacstrap /mnt \
  alsa-utils \
  arch-install-scripts \
  archlinux-keyring \
  archinstall \
  archiso \
  b43-fwcutter \
  base \
  bind-tools \
  brltty \
  broadcom-wl-dkms \
  btrfs-progs \
  clonezilla \
  cloud-init \
  crda \
  cryptsetup \
  darkhttpd \
  ddrescue \
  dhclient \
  diffutils \
  dmraid \
  dnsmasq \
  dosfstools \
  e2fsprogs \
  edk2-shell \
  efibootmgr \
  espeakup \
  ethtool \
  exfatprogs \
  f2fs-tools \
  fatresize \
  fsarchiver \
  fzf \
  gnu-netcat \
  gpart \
  gpm \
  gptfdisk \
  grml-zsh-config \
  grub \
  hdparm \
  intel-ucode \
  ipw2100-fw \
  ipw2200-fw \
  irssi \
  iw \
  iwd \
  jfsutils \
  kitty-terminfo \
  less \
  lftp \
  libfido2 \
  libusb-compat \
  linux \
  linux-atm \
  linux-firmware \
  linux-firmware-marvell \
  livecd-sounds \
  lsscsi \
  lvm2 \
  lynx \
  man-db \
  man-pages \
  mc \
  mdadm \
  memtest86+ \
  mkinitcpio \
  mkinitcpio-archiso \
  mkinitcpio-nfs-utils \
  modemmanager \
  mtools \
  nano \
  nbd \
  ndisc6 \
  networkmanager \
  nfs-utils \
  nilfs-utils \
  nmap \
  ntfs-3g \
  nvme-cli \
  openconnect \
  openssh \
  openvpn \
  partclone \
  parted \
  partimage \
  pcsclite \
  ppp \
  pptpclient \
  pv \
  qemu-guest-agent \
  refind \
  reflector \
  reiserfsprogs \
  rp-pppoe \
  rsync \
  rxvt-unicode-terminfo \
  screen \
  sdparm \
  sg3_utils \
  smartmontools \
  sof-firmware \
  squashfs-tools \
  sudo \
  syslinux \
  systemd-resolvconf \
  tcpdump \
  terminus-font \
  testdisk \
  tmux \
  tpm2-tss \
  udftools \
  usb_modeswitch \
  usbmuxd \
  usbutils \
  neovim \
  virtualbox-guest-utils-nox \
  vpnc \
  wireless-regdb \
  wireless_tools \
  wpa_supplicant \
  wvdial \
  xfsprogs \
  xl2tpd \
  zsh \
  alsa-firmware \
  asoundconf \
  aspell \
  autoconf \
  automake \
  cmake \
  binutils \
  bison \
  bluez \
  bluez-utils \
  brightnessctl \
  dkms \
  dmidecode \
  docker \
  dsniff \
  dunst \
  edk2-ovmf \
  exa \
  fakeroot \
  file \
  findutils \
  firefox \
  flex \
  gawk \
  gcc \
  gcr \
  gettext \
  git \
  glib2 \
  glibc \
  go \
  grep \
  groff \
  gtk2 \
  gzip \
  hping \
  hspell \
  htop \
  hunspell \
  libcap \
  libcap-ng \
  libconfig \
  libev \
  libnotify \
  libpcap \
  libtool \
  libvoikko \
  libx11 \
  libxinerama \
  libxft \
  linux-headers \
  lsof \
  m4 \
  make \
  mdp \
  meson \
  mpc \
  mpd \
  mpv \
  multipath-tools \
  ncdu \
  ncmpcpp \
  neofetch \
  net-tools \
  newsboat \
  nodejs \
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  noto-fonts-extra \
  npm \
  nuspell \
  os-prober \
  pacman \
  pacman-contrib \
  patch \
  pax-utils \
  picom \
  pkgconf \
  pulsemixer \
  python-pip \
  ranger \
  scrot \
  sed \
  stow \
  sxiv \
  the_silver_searcher \
  transmission-cli \
  tree \
  ttf-fira-code \
  ttf-nerd-fonts-symbols \
  unrar \
  unzip \
  upower \
  uthash \
  vi \
  webkit2gtk \
  which \
  xclip \
  xmlstarlet \
  xorg \
  xorg-xinit \
  yarn \
  yt-dlp \
  zathura \
  zathura-pdf-mupdf \
  zip \
  libva-intel-driver \
  libvdpau-va-gl \
  libva-intel-driver \
  libva-utils \
  vulkan-intel \
  xf86-video-intel

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
if [[ ${DISK} != /dev/vda ]]; then
  if [[ ! -d "/sys/firmware/efi" ]]; then
      grub-install --boot-directory=/mnt/boot ${DISK}
      echo "Installed bootloader for BIOS!"
  else
      echo "Skipping (UEFI)!"
  fi
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
echo "Copying configuration files..."
cp -fr /root/.build /root/.dotfiles /root/documents /root/pictures /root/.postinstall.sh /root/.env /mnt/root && echo "Copied successfully"

# Wifi configuration
mkdir -p /mnt/var/lib/iwd
cp -fvr /var/lib/iwd/DJAWEB_E9426.psk /mnt/var/lib/iwd/DJAWEB_E9426.psk
( arch-chroot /mnt /root/.postinstall.sh ) |& tee postinstall.log
cp postinstall.log /mnt/root
