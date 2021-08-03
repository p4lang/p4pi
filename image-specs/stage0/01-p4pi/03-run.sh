#!/bin/bash -e

install -m 644 files/jupyter.service "${ROOTFS_DIR}/lib/systemd/system/"

on_chroot << EOF

mkdir -p /home/pi/jupyter

# Install Jupyter
pip3 install jupyterlab

EOF