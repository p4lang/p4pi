#!/bin/bash -e

echo "${TIMEZONE_DEFAULT}" > "${ROOTFS_DIR}/etc/timezone"
rm "${ROOTFS_DIR}/etc/localtime"

on_chroot << EOF
dpkg-reconfigure -f noninteractive tzdata

# https://github.com/RPi-Distro/pi-gen/issues/271
c_rehash /etc/ssl/certs

pip3 install grpcio

# This service is installed by the 'raspberrypi-sys-mods' package.
# It shuould run on first-boot, before the ssh service.
systemctl enable regenerate_ssh_host_keys.service

EOF
