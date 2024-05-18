#!/bin/bash
#
GIT="."

GRUB_DEF=/etc/default/grub
ETC_MOD=/etc/modules
MODPROBE=/etc/modprobe.d/

MP_IUI="$MODPROBE/iommu_unsafe_interrupts.conf"
MP_KVM="$MODPROBE/kvm.conf"
MP_BL="$MODPROBE/blacklist.conf"
MP_VFIO="$MODPROBE/vfio.conf"

ADDRESS=
lspci
read -p "comma separated addresses of desired device: " ADDRESS
ADDRESS=$(echo $ADDRESS | sed 's/,/\\|/g')
VGA=
IDS=$(lspci -n | grep $ADDRESS | awk {'print $3'} | tr '\n' ','| sed 's/,\s*$//')
read -p "Are any of these VGA cards? Y/n: " VGA

if $(grep -iq '\(^\s*$\)\|y\(es\)\?' <<< $VGA ); then 
	IDS="$IDS disable_vga=1";
	VGA="true"
else
	VGA="false"
fi


echo "adding to $GRUB_DEF"
cat $GIT$GRUB_DEF >> $GRUB_DEF
echo "uncomment relevant line, then execute update-grub for changes to take effect"

echo "#options vfio-pci ids=$IDS" >> $MP_VFIO
echo "#then execute update-initramfs -u" >> $MP_VFIO

for my $i in $MP_IUI $MP_KVM $MP_VFIO; do
	echo "adding to $i"
	cat $GIT$i >> $i
done

if `$VGA`; then
	echo "adding to $MP_BL"
	cat $GIT$MP_BL >> $MP_BL
fi

echo "uncomment relevant lines, then execute 'update-initramfs -u'"
echo "then reboot"
