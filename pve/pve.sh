sed -i 's/enterprise/download/;s/enterprise/no-subscription/;s/https/http/' /etc/apt/sources.list.d/ceph.list

apt update; apt upgrade -y; apt install vim screen git wget curl -y

wget https://raw.githubusercontent.com/foundObjects/pve-nag-buster/635801f8291c801ddf28277b9cf6afd08f0dd2bf/install.sh && md5sum install.sh | grep -q da4ecd060eeaa7e383b6b2583b78ddbb && bash install.sh
