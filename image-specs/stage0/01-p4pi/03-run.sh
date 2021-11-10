#!/bin/bash -e

install -m 644 files/jupyter.service "${ROOTFS_DIR}/lib/systemd/system/"

# T4P4S helper scripts
install -m 644 files/t4p4s.service "${ROOTFS_DIR}/lib/systemd/system/"
install -m 755 files/t4p4s-start "${ROOTFS_DIR}/usr/bin/"
install -m 755 files/t4p4s-p4rtshell "${ROOTFS_DIR}/usr/bin/"
install -m 755 files/setup_eth_wlan_bridge.sh "${ROOTFS_DIR}/root/"

on_chroot << EOF

# Enable t4p4s on boot
systemctl enable t4p4s

mkdir -p /home/pi/jupyter

# Install Jupyter
pip3 install jupyterlab

# Start Jupyter on boot
systemctl enable jupyter.service

EOF