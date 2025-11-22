#!/bin/bash
TMP=$(mktemp -d)
ARCH=$(hostnamectl | grep Architecture: | awk {'print $NF'} | sed 's/arm(64)?/arm64/;s/x86-/amd/')

VER=$(curl -s https://go.dev/VERSION?m=text | grep 'go')
test -d /usr/local/go && sudo mv /usr/local/go $TMP

curl -s https://dl.google.com/go/$VER.linux-$ARCH.tar.gz | sudo tar -C /usr/local -xz || exit 1

sudo rm -rf $TMP;
grep -q '\/usr\/local\/go\/bin\/' <<< "$PATH" || echo 'export "PATH=$PATH:/usr/local/go/bin"' | sudo tee -a /etc/profile
. /etc/profile
