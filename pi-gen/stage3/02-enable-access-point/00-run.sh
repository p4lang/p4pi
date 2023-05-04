#!/bin/bash -e

install -m 644 files/dhcpcd.conf "${ROOTFS_DIR}/etc/"
install -m 644 files/dnsmasq.conf "${ROOTFS_DIR}/etc/"
install -m 644 files/p4pi.conf "${ROOTFS_DIR}/etc/dnsmasq.d/"
install -m 644 files/hostapd.conf "${ROOTFS_DIR}/etc/hostapd/"

install -m 755 files/p4pi-setup-eth-wlan-bridge "${ROOTFS_DIR}/usr/sbin/"
install -m 644 files/p4pi-setup-eth-wlan-bridge.service "${ROOTFS_DIR}/lib/systemd/system/"

install -m 755 files/p4pi-setup "${ROOTFS_DIR}/usr/sbin/"
install -m 644 files/p4pi-setup.service "${ROOTFS_DIR}/lib/systemd/system/"

# Switch off binding to port 53 to avoid conflict with dnsmasq
install -m 644 files/resolved.conf "${ROOTFS_DIR}/etc/systemd/"

on_chroot << EOF

# Enable IPv4 routing
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.d/routed-ap.conf

# Enable access point
systemctl unmask hostapd
systemctl enable hostapd

# Setup DNS if available
systemctl enable systemd-resolved.service

# Create and setup interfaces on startup
systemctl enable systemd-networkd.service
systemctl enable p4pi-setup.service
systemctl enable t4p4s.service

# Enable web UI
systemctl enable p4pi-web

EOF
