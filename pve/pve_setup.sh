cat << EOF > pve_setup.sh
wget https://raw.githubusercontent.com/foundObjects/pve-nag-buster/635801f8291c801ddf28277b9cf6afd08f0dd2bf/install.sh && md5sum install.sh | grep -q da4ecd060eeaa7e383b6b2583b78ddbb && bash install.sh

apt update; apt upgrade -y; apt install vim screen git wget curl -y
EOF
bash pve_setup.sh
