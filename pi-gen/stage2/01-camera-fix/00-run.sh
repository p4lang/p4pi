#!/bin/bash -e
on_chroot << CHEOF
# Remove broken camera packages that fail under QEMU
apt-mark hold python3-kms++ python3-picamera2 2>/dev/null || true
CHEOF
