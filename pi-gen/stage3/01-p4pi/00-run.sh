#!/bin/bash -e

# Display logo on TTY login
install -m 644 files/motd "${ROOTFS_DIR}/etc/"

on_chroot << EOF
echo 'deb http://download.opensuse.org/repositories/home:/p4lang/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4lang.list
curl -fsSL https://download.opensuse.org/repositories/home:p4lang/Raspbian_11/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/home_p4lang.gpg

apt-get -y update

wget https://raw.githubusercontent.com/p4lang/behavioral-model/main/tools/p4dbg.py
mv p4dbg.py /usr/lib/python3/dist-packages/
EOF
