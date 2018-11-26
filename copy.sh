#!/bin/bash

set -e

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "This script needs to be run as root."
    exit
fi



target=${1?Please enter a target}

export user="georg"

# Read Password
read -r -s -p "Password: " password
echo
export password=$password

wget --quiet -nc -O  - https://downloads.raspberrypi.org/raspbian_lite_latest | gunzip | pv | dd of="$target" bs=4M conv=fsync

blockdev --rereadpt "$target"

# Enable SSH
mount "${target}1" /mnt
touch /mnt/ssh
umount /mnt



mount "${target}2" /mnt


# Set wifi
cat wpa_supplicant.conf >> /mnt/etc/wpa_supplicant/wpa_supplicant.conf


# Setup user

cat << EOF | systemd-nspawn -D /mnt bin/bash
useradd -G sudo -m --shell /bin/bash "$user"
echo -e "$password\\n$password\\n" | passwd "$user"

apt update
yes | apt upgrade

cd "/home/$user"
curl -Lo log2ram.tar.gz https://github.com/azlux/log2ram/archive/master.tar.gz
tar xf log2ram.tar.gz
cd log2ram-master
chmod +x install.sh && sudo ./install.sh
mv /etc/cron.hourly/log2ram /etc/cron.daily/log2ram
cd ..
rm -rf log2ram-master log2ram.tar.gz

userdel -r pi

EOF


# Copy ssh public key
mkdir "/mnt/home/$user/.ssh/"
cp authorized_keys "/mnt/home/$user/.ssh/authorized_keys"


umount /mnt

echo "Done"