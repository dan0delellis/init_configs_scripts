#!/bin/bash
../ubuntu/defaults.sh
sudo apt install -y abcde flac cifs-utils
sudo mv /etc/abcde.conf{,.default}
sudo cp abcde.conf /etc/.
sudo cat ../all/fstab/media >> /etc/fstab
sudo mkdir /mnt/media
sudo mkdir /mnt/usb
sudo mount -a
