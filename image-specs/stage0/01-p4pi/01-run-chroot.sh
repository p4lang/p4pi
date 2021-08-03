#!/bin/bash -e

# Add P4Pi packages repository: https://build.opensuse.org/project/show/home:rstoyanov
echo 'deb http://download.opensuse.org/repositories/home:/rstoyanov/Debian_Testing/ /' | tee /etc/apt/sources.list.d/home:rstoyanov.list
curl -fsSL https://download.opensuse.org/repositories/home:rstoyanov/Debian_Testing/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_rstoyanov.gpg > /dev/null
apt-get update

apt-get --fix-broken install

apt-fast install -o Dpkg::Options::="--force-overwrite" --allow-downgrades --fix-missing -y \
	p4pi-linux-image-5.10.52-v8+ \
	p4pi-linux-headers-5.10.52-v8+ \
	p4lang-pi \
	p4lang-p4c \
	p4lang-bmv2 \
	p4pi-web

mv /boot/vmlinuz-5.10.52-v8+ /boot/kernel8.img

# Enable web UI
systemctl enable p4pi-web

# Install T4P4S dependencies
pip3 install meson pyelftools pybind11 pysimdjson ipaddr scapy dill setuptools backtrace ipdb termcolor colored pyyaml ujson ruamel.yaml

if [ -z "$(ls -A /root/t4p4s)" ] ; then
	git clone --recursive https://github.com/p4edge/t4p4s /root/t4p4s
fi
