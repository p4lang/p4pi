#!/bin/bash -e

# Add P4Edge packages repositories:
echo 'deb [signed-by=/usr/share/keyrings/p4edge-archive-keyring.gpg] http://download.opensuse.org/repositories/home:/p4edge/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4edge.list
curl -fsSL https://download.opensuse.org/repositories/home:p4edge/Raspbian_11/Release.key | gpg --dearmor > /usr/share/keyrings/p4edge-archive-keyring.gpg

echo 'deb [signed-by=/usr/share/keyrings/p4edge-kernel-archive-keyring.gpg] http://download.opensuse.org/repositories/home:/p4edge:/kernel/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4edge-kernel.list
curl -fsSL https://download.opensuse.org/repositories/home:p4edge:/kernel/Raspbian_11/Release.key | gpg --dearmor > /usr/share/keyrings/p4edge-kernel-archive-keyring.gpg

#echo 'deb [signed-by=/usr/share/keyrings/p4edge-testing-archive-keyring.gpg] http://download.opensuse.org/repositories/home:/p4edge:/testing/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4edge-testing.list
#curl -fsSL https://download.opensuse.org/repositories/home:p4edge:/testing/Raspbian_11/Release.key | gpg --dearmor > /usr/share/keyrings/p4edge-testing-archive-keyring.gpg

#echo 'deb [signed-by=/usr/share/keyrings/p4edge-testing-archive-keyring.gpg] http://download.opensuse.org/repositories/home:/p4edge:/p4lang-testing/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4edge-p4lang-testing.list
#curl -fsSL https://download.opensuse.org/repositories/home:/p4edge:/p4lang-testing/Raspbian_11/Release.key | gpg --dearmor > /usr/share/keyrings/p4edge-p4lang-testing-archive-keyring.gpg

echo 'deb [signed-by=/usr/share/keyrings/p4edge-testing-archive-keyring.gpg] http://download.opensuse.org/repositories/home:/IcePhoenix:/p4edge:/testing/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4edge-testing.list
curl -fsSL https://download.opensuse.org/repositories/home:/IcePhoenix:/p4edge:/testing/Raspbian_11/Release.key | gpg --dearmor > /usr/share/keyrings/p4edge-testing-archive-keyring.gpg


apt-get update

apt-get --fix-broken install

apt-fast install -o Dpkg::Options::="--force-overwrite" --allow-downgrades --fix-missing -y \
  p4lang-pi \
  p4lang-p4c \
  p4lang-bmv2 \
  p4edge-t4p4s \
  p4edge-examples \
  p4edge-web \
  p4edge-linux-image-5.15.33-v8+ \
  p4edge-linux-headers-5.15.33-v8+ \
  lsof

mv /root/t4p4s /root/t4p4s-old

#upgrade t4p4s
wget http://lakis.web.elte.hu/p4edge-t4p4s.deb
dpkg -i p4edge-t4p4s.deb

mv /root/t4p4s-old/examples /root/t4p4s
rm -rf /root/t4p4s-old

cp /root/t4p4s/setup_eth_wlan_bridge.sh /root/

pip install more-itertools nnpy

wget https://raw.githubusercontent.com/p4lang/behavioral-model/main/tools/p4dbg.py
mv p4dbg.py /usr/lib/python3/dist-packages/

mv /boot/vmlinuz-5.15.33-v8+ /boot/kernel8.img

# Enable web UI
systemctl enable p4edge-web

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

mkdir /root/bmv2
mkdir /root/bmv2/bin

git clone --depth=1 -b bmv2 https://github.com/P4EDGE/examples.git /root/bmv2/examples

mkdir /root/bmv2/examples/uploaded_switch

