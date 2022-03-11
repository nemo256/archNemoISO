#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="archNemo"
iso_label="archNemo_0.0.1"
iso_publisher="Amine Neggazi <https://amineneggazi.vercel.app>"
iso_application="Arch Nemo"
iso_version="0.0.1"
install_dir="archNemo"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
)
