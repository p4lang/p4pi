#!/bin/bash -e

# Add P4Pi packages repository: https://build.opensuse.org/project/show/home:rstoyanov
echo 'deb http://download.opensuse.org/repositories/home:/rstoyanov/Debian_11/ /' | tee /etc/apt/sources.list.d/home:rstoyanov.list
curl -fsSL https://download.opensuse.org/repositories/home:rstoyanov/Debian_11/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_rstoyanov.gpg > /dev/null
apt-get update

apt-get --fix-broken install

apt-fast install -o Dpkg::Options::="--force-overwrite" --allow-downgrades --fix-missing -y \
	p4pi-linux-image-5.10.60-v8+ \
	p4pi-linux-headers-5.10.60-v8+ \
	p4pi-examples \
	p4lang-pi \
	p4lang-p4c \
	p4lang-bmv2 \
	p4pi-web

mv /boot/vmlinuz-5.10.60-v8+ /boot/kernel8.img

# Enable web UI
systemctl enable p4pi-web

# Install T4P4S dependencies
pip3 install meson pyelftools pybind11 pysimdjson ipaddr scapy dill setuptools backtrace ipdb termcolor colored pyyaml ujson ruamel.yaml p4runtime-shell

if [ -z "$(ls -A /root/t4p4s)" ] ; then
	git clone --recursive https://github.com/p4edge/t4p4s /root/t4p4s
fi

git clone -b v1.37.0 --recursive --shallow-submodules --depth=1 https://github.com/grpc/grpc /root/grpc
mkdir /root/PI && cd /root/PI
git init
git remote add origin https://github.com/p4lang/PI
git fetch --depth 1 origin a5fd855d4b3293e23816ef6154e83dc6621aed6a
git checkout FETCH_HEAD
git submodule update --init --recursive --depth=1
git clone --depth=1 https://github.com/P4ELTE/P4Runtime_GRPCPP /root/P4Runtime_GRPCPP
cd /root/P4Runtime_GRPCPP
./install.sh
./compile.sh

cat << EOT >>/etc/bash.bashrc

# T4P4S env variables
export P4PI=/root/PI
export GRPCPP=/root/P4Runtime_GRPCPP
export GRPC=/root/grpc
EOT
