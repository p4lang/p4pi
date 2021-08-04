#!/bin/bash -e

install -m 644 files/sources.list "${ROOTFS_DIR}/etc/apt/"
install -m 644 files/raspi.list "${ROOTFS_DIR}/etc/apt/sources.list.d/"
install -m 644 files/apt-fast.list "${ROOTFS_DIR}/etc/apt/sources.list.d/"
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list"
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list.d/raspi.list"

install -m 644 files/cmdline.txt "${ROOTFS_DIR}/boot/"
install -m 644 files/config.txt "${ROOTFS_DIR}/boot/"

install -d "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
install -m 644 files/noclear.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/noclear.conf"
install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"

echo "${TARGET_HOSTNAME}" > "${ROOTFS_DIR}/etc/hostname"
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" >> "${ROOTFS_DIR}/etc/hosts"
echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> "${ROOTFS_DIR}/etc/hosts"
echo "127.0.0.1   ${TARGET_HOSTNAME}" >> "${ROOTFS_DIR}/etc/hosts"

on_chroot apt-key add - < files/raspberrypi.gpg.key
on_chroot apt-key add - < files/apt-fast.gpg.key

on_chroot << EOF

dpkg --add-architecture arm64

apt-get update
apt-get install -y -qq apt-fast
apt-fast dist-upgrade -y

if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" ${FIRST_USER_NAME}
fi
echo "${FIRST_USER_NAME}:${FIRST_USER_PASS}" | chpasswd
echo "root:root" | chpasswd

EOF
