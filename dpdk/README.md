# DPDK

## Compile from source (~10m)
Tested with v20.08
```bash
git clone -b v20.08 git://dpdk.org/dpdk
```

To use pcap poll mode driver, edit `config/common_base`: (newer versions with meson automatically detect if libpcap is installed)
```
CONFIG_RTE_LIBRTE_PMD_PCAP=y
```

Compile
```bash
meson build
cd build && ninja -j4
sudo ninja install
sudo ldconfig
```

## Run
Copy basic_mirror, make and run:
```
sudo ./build/basic_mirror -l 2,3 -n 4 --no-pci --no-huge --vdev net_pcap0,iface=eth0 -- -p 0x1
```

