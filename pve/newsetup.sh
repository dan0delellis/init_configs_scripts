#!/bin/bash
apt install -y vim screen git curl wget patch

wget $(curl -s https://api.github.com/repos/daniel-delellis/pve-no-subsription/releases/latest | grep tarball_url | awk {'print $NF'} | sed 's/[,"]//g') -O pve_no_subscription.tar.gz

DIR=$(tar f pve_no_subscription.tar.gz -t | head -n1)

tar xvfz pve_no_subscription.tar.gz
bash $DIR/apply.sh "first-setup"
