#!/bin/bash -e

on_chroot << EOF
mv /boot/vmlinuz-5.15.84-v8-p4pi /boot/p4pi-kernel8.img
echo "kernel=p4pi-kernel8.img" >> /boot/config.txt
EOF
