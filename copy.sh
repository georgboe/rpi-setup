#!/bin/bash

set -e

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "This script needs to be run as root."
    exit
fi



target=${1?Please enter a target}

export timezone="Europe/Oslo"

USER=$(whiptail --inputbox "Enter a username" 8 78 georg --title "Admin account setup" 3>&1 1>&2 2>&3)
export user=$USER

# Read Password
PASSWORD=$(whiptail --passwordbox "Please enter a password" 8 78 --title "Admin account setup" 3>&1 1>&2 2>&3)
export password=$PASSWORD

(pv -n 2019-06-20-raspbian-buster-lite.img | dd of="$target" bs=4M conv=fsync) 2>&1 | whiptail --gauge "Copying image to $target" 8 78 0

blockdev --rereadpt "$target"

# Enable SSH
mount "${target}1" /mnt
# echo " cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory" >> /mnt/cmdline.txt

echo "temp_soft_limit=70" >> /mnt/config.txt
touch /mnt/ssh
umount /mnt



mount "${target}2" /mnt


# Set wifi
cat wpa_supplicant.conf >> /mnt/etc/wpa_supplicant/wpa_supplicant.conf


# Setup user

cat << EOF | systemd-nspawn --pipe -D /mnt bin/bash
useradd -G sudo,video -m --shell /bin/bash "$user"
echo -e "$password\\n$password\\n" | passwd "$user"

apt update

echo unattended-upgrades "unattended-upgrades/enable_auto_updates" boolean true | debconf-set-selections
echo unattended-upgrades "unattended-upgrades/origins_pattern" string "origin=Debian,codename=${distro_codename},label=Debian-Security" | debconf-set-selections
apt install -y unattended-upgrades 

rm /etc/localtime
echo "$timezone" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

echo "tmpfs /var/log tmpfs defaults,noatime,mode=0755,size=40M 0 0" >> /etc/fstab

cp /usr/share/systemd/tmp.mount /etc/systemd/system/
systemctl enable tmp.mount

# dphys-swapfile swapoff
# dphys-swapfile uninstall
# systemctl stop dphys-swapfile
# systemctl disable dphys-swapfile

userdel -r pi

apt install -y vim rng-tools
echo "HRNGDEVICE=/dev/hwrng" >> /etc/default/rng-tools

EOF


# Copy ssh public key
mkdir "/mnt/home/$user/.ssh/"
cp authorized_keys "/mnt/home/$user/.ssh/authorized_keys"


umount /mnt

echo "Done"
