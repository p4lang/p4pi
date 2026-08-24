#!/bin/bash -e
on_chroot << EOF
set -e
echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries

# --- Build dependencies (p4c official list + BMv2 extras) ---
apt-get -y install --no-install-recommends \
    autoconf automake bison build-essential ccache cmake flex git g++ \
    libboost-dev libboost-program-options-dev libboost-thread-dev \
    libboost-test-dev libboost-system-dev libboost-filesystem-dev \
    libboost-iostreams-dev libboost-graph-dev \
    libevent-dev libffi-dev libgmp-dev libjsoncpp-dev libnanomsg-dev \
    libpcap-dev libreadline-dev libssl-dev libthrift-dev libtool libtool-bin \
    libxxhash-dev libjudy-dev libgc-dev libfl-dev llvm \
    pkg-config python3-dev python3-pip python3-six python3-thrift \
    python3-setuptools python3-ply thrift-compiler wget curl ca-certificates \
    tcpdump libprotobuf-dev libprotoc-dev protobuf-compiler

# --- BMv2 1.15.5 ---
cd /tmp
git clone --depth 1 --branch 1.15.5 https://github.com/p4lang/behavioral-model.git
cd behavioral-model
./autogen.sh
./configure
make -j2
make install
ldconfig
cd /tmp && rm -rf behavioral-model

# --- p4c v1.2.5.16 (BMv2 + DPDK backends only) ---
cd /tmp
git clone --depth 1 --branch v1.2.5.16 --recursive https://github.com/p4lang/p4c.git
cd p4c
mkdir build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=RELEASE \
  -DENABLE_BMV2=ON \
  -DENABLE_DPDK=ON \
  -DENABLE_EBPF=OFF \
  -DENABLE_UBPF=OFF \
  -DENABLE_P4TEST=OFF \
  -DENABLE_P4TC=OFF \
  -DENABLE_P4FMT=OFF \
  -DENABLE_TEST_TOOLS=OFF \
  -DENABLE_DOCS=OFF \
  -DENABLE_GTESTS=OFF
make -j2
make install
ldconfig
cd /tmp && rm -rf p4c

echo "p4c and BMv2 built from source"
EOF
