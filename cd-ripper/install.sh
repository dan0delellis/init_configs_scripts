#!/bin/bash
sudo apt install -y abcde flac cifs-utils
sudo mv /etc/abcde.conf{,.default}
sudo mv abcde.conf /etc/.
base64 -d <<< "Ly8xMC4xLjAuNS9tZWRpYSAvbW50L21lZGlhIGNpZnMgdmVycz0zLjAsdWlkPTEwMDAsZ2lkPTEwMDAsdXNlcj1zYW1iYXNoYXJlcyxwYXNzPWRvbmtleWJvbmVyLGRlZmF1bHRzLF9uZXRkZXYgMCAwCg==" | sudo tee -a /etc/fstab
sudo mkdir /mnt/media
sudo mkdir /mnt/usb
sudo mount -a
