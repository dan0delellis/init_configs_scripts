#!/bin/bash

#friendly warning
warning=( 
    "bXkgYnJvdGhlciBpbiBjaHJpc3QsCg=="
    "eW91IGFyZSBhYm91dCB0byBpbmplY3QgYW4K" 
    "QVJCSVRSQVJZCg==" 
    "Q09ERQo=" 
    "RVhFQ1VUSU9OCg==" 
    "RVhQTE9JVAo=" 
    "aW50byB5b3VyIGxvY2FsIG5ldHdvcmsuCg==" 
    "aGF2ZSB5b3UgbG9zdCB5b3VyIG1pbmQ/Cg=="
)
for i in ${warning[*]} ; do
    base64 -d <<< $i
    sleep 0.5
done
sleep 2

#var setup
TFTPDIR="/var/lib/tftpboot"
PXEDIR="$TFTPDIR/pxelinux.cfg"
MTPDIR="$PXEDIR/memtest86_plus"
REPO="https://github.com/memtest86plus/memtest86plus/"

set -e

#work environment setup
WORKDIR=$(mktemp -d)
REPODIR="$WORKDIR/memtest86plus"
GIT="git -C $REPODIR"

#system setup
apt update
apt install -y make gcc binutils xorriso tftpd-hpa  syslinux pxelinux

#create the directory tree for our tftpboot server and hosted files
mkdir -p $MTPDIR

#download them sources and switch to the last release
git -C $WORKDIR clone $REPO
$GIT checkout tags/$(${GIT} tag | tail -n 1) -b temp-branch-name

#compile the 64bit version and move the results to our tftpboot directory, 
#then delete the paper trail so you'll never know what happened if something goes wrong
make -C $REPODIR/build64 iso
mv $REPODIR/build64/memtest.* $MTPDIR/.
rm -rf $WORKDIR

#copy the syslinux/pxelinux files into place
cp /usr/lib/syslinux/modules/bios/* $TFTPDIR/.
cp /usr/lib/PXELINUX/pxelinux.0 $TFTPDIR/.

#write the defaults file for tftpd
cat << EOF > /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
EOF

#write the default pxeboot file
cat << EOF > $PXEDIR/default
default menu.c32
timeout 50

LABEL next boot device
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

#lets rock
systemctl restart tftpd-hpa
systemctl status tftpd-hpa
