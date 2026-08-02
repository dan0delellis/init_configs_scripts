#!/bin/bash
ONE_API_KEY_URL="https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB"
ONE_API_KEY_PATH="/usr/share/keyrings/oneapi-archive-keyring.gpg"
#INTEL_REPO_KEY_URL="https://repositories.intel.com/gpu/intel-graphics.key"
#INTEL_REPO_KEY_PATH="/usr/share/keyrings/intel-graphics.gpg"
DRIVERS_LIST="/etc/apt/sources.list.d/intel-gpu-drivers.list"
ONEAPI_LIST="/etc/apt/sources.list.d/one-api.list"

TMPDIR=$(mktemp -d)

LTS="stonking resolute questing plucky noble jammy"
ERR=

check_err() {
        if [ ! "$ERR" = "" ]; then
                echo -e $ERR
		rm -rfv $TMPDIR
		sudo rm -v $DRIVERS_LIST $ONEAPI_LIST
                exit 1
        fi
}

sudo true || ERR="superuser privs required"
check_err

#TODO move this logic to be activated if $1 and $2 are nonemptyu
INTEL_GPU_LTS=
if [ ! "$1" = "" ]; then
        INTEL_GPU_LTS=$1
fi

lts=$2
if [ ! $INTEL_GPU_LTS = "" ] && [! $lts = "" ]; then
	curl $INTEL_REPO_KEY_URL -o "$TMPDIR/apt.pub" #| sudo gpg --dearmor --yes --output $INTEL_REPO_KEY_PATH
	sudo gpg  --output "$INTEL_REPO_KEY_PATH" --yes --dearmor "$TMPDIR/apt.pub"

	echo "deb [arch=amd64 signed-by=$INTEL_REPO_KEY_PATH] https://repositories.intel.com/gpu/ubuntu ${lts}/lts/${INTEL_GPU_LTS} unified" | sudo tee /etc/apt/sources.list.d/intel-gpu-drivers.list
fi

sudo apt update
sudo apt upgrade -y
sudo apt install -y gnupg wget vim git curl cmake pkg-config build-essential

curl $ONE_API_KEY_URL -o "$TMPDIR/oneapi.pub" #| sudo gpg --dearmor --yes --output $ONE_API_KEY_PATH
sudo gpg --output "$ONE_API_KEY_PATH" --yes --dearmor "$TMPDIR/oneapi.pub"

echo "deb [signed-by=$ONE_API_KEY_PATH] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/one-api.list
sudo apt update

sudo apt install intel-oneapi-toolkit ocl-icd-libopencl1 intel-opencl-icd libze1 libze-intel-gpu1 libze-intel-gpu-dev -y
