# Raspbian setup script

I was doing the same steps for every Raspberry Pi I set up, so I created this script to automate the process.

It enables SSH, configures WiFi, adds a user with sudo privileges and sets up public key authentication, updates the system, installs [log2ram](https://github.com/azlux/log2ram) and removes the default pi user.

## Installation

_Install dependencies_

    $ sudo dnf install pv systemd-container wget qemu-user-static

_Configure `wpa_supplicant.conf`_

    $ mv wpa_supplicant.conf.example wpa_supplicant.conf
    $ vim wpa_supplicant.conf

_Configure `authorized_keys`_

    $ cp ~/.ssh/id_rsa.pub .

## Usage

Find the device that you want to install Raspbian to and make sure none of the partitions are mounted.

    $ lsblk
    NAME                                          MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
    sdd                                             8:48   1  14.8G  0 disk  
    └─sdd1                                          8:49   1  14.8G  0 part  

Now run the script as root with the memory card device as an argument.

    $ sudo ./copy.sh /dev/sdd

## License

Distributed under the MIT license. See LICENSE for more information.