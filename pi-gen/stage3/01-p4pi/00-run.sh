#!/bin/bash -e

# Display logo on TTY login
install -m 644 files/motd "${ROOTFS_DIR}/etc/"

on_chroot << EOF
echo 'deb [signed-by=/usr/share/keyrings/p4edge-kernel-archive-keyring.gpg] http://download.opensuse.org/repositories/home:/p4edge:/kernel/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4edge-kernel.list
curl -fsSL https://download.opensuse.org/repositories/home:p4edge:/kernel/Raspbian_11/Release.key | gpg --dearmor > /usr/share/keyrings/p4edge-kernel-archive-keyring.gpg

echo 'deb [signed-by=/usr/share/keyrings/p4edge-p4lang-testing-archive-keyring.gpg] http://download.opensuse.org/repositories/home:/p4edge:/p4lang-testing/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4edge-p4lang-testing.list
curl -fsSL https://download.opensuse.org/repositories/home:/p4edge:/p4lang-testing/Raspbian_11/Release.key | gpg --dearmor > /usr/share/keyrings/p4edge-p4lang-testing-archive-keyring.gpg

echo 'deb [signed-by=/usr/share/keyrings/p4edge-archive-keyring.gpg] http://download.opensuse.org/repositories/home:/p4edge/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4edge.list
curl -fsSL https://download.opensuse.org/repositories/home:/p4edge/Raspbian_11/Release.key | gpg --dearmor > /usr/share/keyrings/p4edge-archive-keyring.gpg

echo 'deb [signed-by=/usr/share/keyrings/p4pi-unstable-archive-keyring.gpg] http://download.opensuse.org/repositories/home:/p4pi:/unstable/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4pi-unstable.list
curl -fsSL https://download.opensuse.org/repositories/home:/p4pi:/unstable/Raspbian_11/Release.key | gpg --dearmor > /usr/share/keyrings/p4pi-unstable-archive-keyring.gpg

apt-get -y update

wget https://raw.githubusercontent.com/p4lang/behavioral-model/main/tools/p4dbg.py
mv p4dbg.py /usr/lib/python3/dist-packages/

echo 'kernel="vmlinuz-5.15.33-v8+"' >> /boot/config.txt

# Enable web UI
systemctl enable p4pi-web

EOF

