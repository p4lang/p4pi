# T4P4S

Only python 3.7 is available through apt, need to install newer version from source

## Python 3.9.2 (~20m)
[Based on this](https://www.ramoonus.nl/2021/01/21/how-to-install-python-3-9-1-on-raspberry-pi/)

Download [source](https://www.python.org/downloads/source/) and altinstall:

```bash
sudo apt-get install -y libffi-dev libssl-dev
wget https://www.python.org/ftp/python/3.9.2/Python-3.9.2.tar.xz
tar xf Python-3.9.2.tar.xz
cd Python-3.9.2
./configure --enable-optimizations
make -j4
sudo make altinstall
```
## Bootstrap

Create a symlink to absl headers
```
sudo ln -s [path-to-bootstrap]/grpc/third_party/abseil-cpp/absl /usr/include/absl
```

Download the modified bootstrap script and run:
```bash
P4C_COMMIT_DATE=2021-03-08 GRPC_TAG=v1.36.4 PYTHON3=python3.9 T4P4S_CC=gcc T4P4S_CXX=g++ T4P4S_LD=bfd . ./bootstrap-t4p4s.sh
```
Every python package now installs through pip. This needed because, some package is not available or outdated through apt. (Plus some minor bash tweaks)

## Run basic mirror
Copy `basic_mirror.p4` to examples
Add to `opts_dpdk.cfg`
```bash
pieal   -> ealopts += -l 2 -n 4 --no-pci --vdev net_pcap0,iface=eth0
piports -> cmdopts += -p 0x0 --config "\"(0,0,2)\""
```
Add to examples.cfg
```bash
basic_mirror arch=dpdk hugepages=1024 model=v1model smem vethmode pieal piports
```
Run
```bash
PYTHON3=python3.9 ./t4p4s.sh :basic_mirror
```
