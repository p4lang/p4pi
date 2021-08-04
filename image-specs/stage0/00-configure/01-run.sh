#!/bin/bash -e

install -m 755 files/resize2fs_once "${ROOTFS_DIR}/etc/init.d/"
install -d "${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d"
install -m 644 files/ttyoutput.conf "${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d/"
install -m 644 files/50raspi "${ROOTFS_DIR}/etc/apt/apt.conf.d/"
install -m 644 files/console-setup "${ROOTFS_DIR}/etc/default/"
install -m 755 files/rc.local "${ROOTFS_DIR}/etc/"
install -m 644 files/bash.bashrc "${ROOTFS_DIR}/etc/"

on_chroot << EOF
# Update locales
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_GB.UTF-8

systemctl disable hwclock.sh

if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
EOF

if [ "${USE_QEMU}" = "1" ]; then
	echo "enter QEMU mode"
	install -m 644 files/90-qemu.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
	on_chroot << EOF
systemctl disable resize2fs_once
EOF
	echo "leaving QEMU mode"
else
	on_chroot << EOF
systemctl enable resize2fs_once
EOF
fi

on_chroot <<EOF
for GRP in input spi i2c gpio; do
	groupadd -f -r "\$GRP"
done
for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev; do
  adduser $FIRST_USER_NAME \$GRP
done
EOF

on_chroot << EOF
setupcon --force --save-only -v
EOF

on_chroot << EOF
usermod --pass='*' root
EOF

on_chroot << EOF
# Enable color in the .bashrc file.
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /home/${FIRST_USER_NAME}/.bashrc
EOF

rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*
