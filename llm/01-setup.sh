#!/bin/bash
set -e

# install things needed to get gpg keys installed
sudo apt-get update
sudo apt-get install -y --no-install-recommends ca-certificates curl  gnupg2

#add repos that have nvidia drivers
source /etc/os-release
sudo echo "deb http://deb.debian.org/debian/ $VERSION_CODENAME non-free contrib" > /etc/apt/sources.list.d/non-free.list

#add nvidia cuda keyring and apt list
#wget https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb
#sudo dpkg -i cuda-keyring_1.1-1_all.deb

# install nvidia container package
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# add docker repo
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y nvidia-driver firmware-misc-nonfree nvidia-cuda-toolkit nvidia-container-toolkit docker-ce docker-ce-cli containerd.io build-essential cmake git libcurl4-openssl-dev linux-headers-amd64

#wait for networking
for i in $(seq 1 60); do echo "attempt $i"; host github.com || sleep 1 && break; done

# 4. Clone and compile llama.cpp locally targeting Compute Capability 7.5
if [ ! -d "llama.cpp" ]; then
    git -C /root clone https://github.com/ggml-org/llama.cpp.git
else
	git -C /root/llama.cpp pull -r
fi

echo "@reboot root $(realpath 02-build.sh)" | sudo tee /etc/cron.d/build-after-boot
echo "ready 2 reboot"
