#!/bin/bash

apt-get update
apt-get dist-upgrade -y
apt-get install -y apt-utils autoconf automake avahi-daemon bash-completion bind9-dnsutils bison bridge-utils build-essential ca-certificates ccache clang cmake console-setup cpp crda curl dbus debconf-utils dosfstools doxygen dpdk dpdk-dev dpdk-doc dphys-swapfile e2fsprogs ed ethtool fake-hwclock fbset fdisk flex gdb git hardlink htop iperf iperf3 iputils-ping isc-dhcp-client isc-dhcp-common keyboard-configuration less libboost-dev libboost-filesystem-dev libboost-graph-dev libboost-iostreams-dev libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev libbsd-dev libc-devtools libc++-dev libc6-dev libcrypto++-dev libelf-dev libevent-dev libfdt-dev libffi-dev libfl-dev libfreetype6-dev libgc-dev libgmp-dev libgmpxx4ldbl libgrpc-dev libgrpc++-dev libibverbs-dev libjansson-dev libjudy-dev libmicrohttpd-dev libmtp-runtime libnanomsg-dev libnuma-dev libpcap-dev libprotobuf-c-dev libprotobuf-dev libprotoc-dev libreadline-dev librte-mempool-ring21 librte-mempool21 librte-meta-allpmds librte-meta-baseband librte-meta-bus librte-meta-compress librte-meta-crypto librte-meta-event librte-meta-mempool librte-meta-net librte-meta-raw librte-net-af-packet21 librte-net-bond21 librte-net-e1000-21 librte-net-fm10k21 librte-net-i40e21 librte-net-ixgbe21 librte-net-kni21 librte-net-mlx4-21 librte-net-mlx5-21 librte-net-netvsc21 librte-net-pcap21 librte-net-tap21 librte-net-tap21 librte-net-thunderx21 librte-net-vdev-netvsc21 librte-net-vhost21 librte-net-virtio21 librte-net-vmxnet3-21 libssl-dev libthrift-dev libtool libtool-bin lld llvm locales lshw lua5.1 luajit man-db manpages-dev ncdu net-tools netbase netcat ninja-build ntfs-3g parted pciutils pkg-config policykit-1 protobuf-c-compiler protobuf-compiler protobuf-compiler-grpc psmisc python-is-python3 python3-gpiozero python3-ipaddr python3-pip python3-ply python3-protobuf python3-pyelftools python3-pyroute2 python3-scapy python3-setuptools python3-thrift python3-wheel rng-tools rsync ssh ssh-import-id strace sudo tcpdump thrift-compiler tmux traceroute unzip usb-modeswitch usbutils v4l-utils vim wget wireless-tools wireshark zip zlib1g-dev

# Create default user
adduser --disabled-password --gecos "" "pi"
echo "pi:raspberry" | chpasswd

# Add user to groups
for GRP in input spi i2c gpio; do
	groupadd -f -r "${GRP}"
done

for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev; do
  adduser pi "${GRP}"
done

# Enable bash color
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /home/pi/.bashrc

# Enable start-up services
systemctl enable ssh
systemctl enable t4p4s
systemctl enable p4pi-setup

# Set timezone
echo "Europe/London" > /etc/timezone

# Install T4P4S dependencies
pip3 install meson pyelftools pybind11 pysimdjson ipaddr scapy dill setuptools backtrace ipdb termcolor colored pyyaml ujson ruamel.yaml p4runtime-shell

git clone --recursive https://github.com/p4edge/t4p4s /root/t4p4s

git clone -b v1.37.0 --recursive --shallow-submodules --depth=1 https://github.com/grpc/grpc /root/grpc
mkdir -p /root/PI
cd /root/PI || exit 1
git init
git remote add origin https://github.com/p4lang/PI
git fetch --depth 1 origin a5fd855d4b3293e23816ef6154e83dc6621aed6a
git checkout FETCH_HEAD
git submodule update --init --recursive --depth=1
git clone --depth=1 https://github.com/P4ELTE/P4Runtime_GRPCPP /root/P4Runtime_GRPCPP
cd /root/P4Runtime_GRPCPP || exit 1
./install.sh
./compile.sh

# Add T4P4S environment variables
cat << EOT >>/etc/bash.bashrc

# T4P4S env variables
export P4PI=/root/PI
export GRPCPP=/root/P4Runtime_GRPCPP
export GRPC=/root/grpc
EOT

# Install Jupyter Notebooks
mkdir -p /home/pi/jupyter
pip3 install jupyterlab
systemctl enable jupyter.service