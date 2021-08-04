#!/bin/bash -e

install -m 644 files/dhcpcd.conf "${ROOTFS_DIR}/etc/"
install -m 644 files/dnsmasq.conf "${ROOTFS_DIR}/etc/"
install -m 644 files/hostapd.conf "${ROOTFS_DIR}/etc/hostapd/"
install -m 644 files/rfkill-unblock-wifi.service "${ROOTFS_DIR}/lib/systemd/system/"

# Create a bridge device and populate the bridge
install -m 644 files/bridge-br0.netdev "${ROOTFS_DIR}/etc/systemd/network/"
install -m 644 files/br0-member-wlan0.network "${ROOTFS_DIR}/etc/systemd/network/"

install -m 755 files/p4pi-setup "${ROOTFS_DIR}/usr/sbin/"
install -m 644 files/p4pi-setup.service "${ROOTFS_DIR}/lib/systemd/system/"

on_chroot << EOF

# Enable IPv4 routing
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.d/routed-ap.conf

# Enable access point
systemctl unmask hostapd
systemctl enable hostapd

# Create and setup interfaces on startup
systemctl enable systemd-networkd
systemctl enable p4pi-setup.service

sed -i 's|#DAEMON_CONF.*$|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

EOF