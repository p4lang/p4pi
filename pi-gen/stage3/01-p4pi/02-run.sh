#!/bin/bash -e

on_chroot << EOF
mv vmlinuz-5.15.84-v8+ p4pi-kernel8.img
echo "kernel=p4pi-kernel8.img" >> config.txt
EOF
