#!/bin/bash -e
# Display logo on TTY login
install -m 644 files/motd "${ROOTFS_DIR}/etc/"
on_chroot << CHEOF
apt-get -y update
CHEOF
