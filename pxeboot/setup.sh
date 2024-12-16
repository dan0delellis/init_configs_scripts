#!/bin/bash
TFTPDIR="/var/lib/tftpboot"
PXEDIR="$TFTPDIR/pxelinux.cfg"
MTPDIR="$PXEDIR/memtest86_plus"
REPO="https://github.com/memtest86plus/memtest86plus/"

set -e

WORKDIR=$(mktemp -d)
REPODIR="$WORKDIR/memtest86plus"
GIT="git -C $REPODIR"

apt update
apt install -y make gcc binutils xorriso tftpd-hpa  syslinux pxelinux

mkdir -p $MTPDIR

git -C $WORKDIR clone $REPO
$GIT checkout tags/$(${GIT} tag | tail -n 1) -b temp-branch-name

make -C $REPODIR/build64 iso
mv $REPODIR/build64/memtest.* $MTPDIR/.
rm -rf $WORKDIR

cp /usr/lib/syslinux/modules/bios/* $TFTPDIR/.
cp /usr/lib/PXELINUX/pxelinux.0 $TFTPDIR/.

cat << EOF > /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
EOF

cat << EOF > $PXEDIR/default
default menu.c32
timeout 50

LABEL boot from local disk
    LOCALBOOT 0

LABEL memtest efi
  MENU LABEL MEMTEST86 (EFI)
  KERNEL pxelinux.cfg/memtest86_plus/memtest.efi
  append vga=788

LABEL memtest bios
  MENU LABEL MEMTEST86 (bios)
  KERNEL pxelinux.cfg/memtest86_plus/memtest.bin
  APPEND vga=788
EOF

systemctl restart tftpd-hpa
systemctl status tftpd-hpa
