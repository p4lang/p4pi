
# P4Pi Kernel

The default Raspberry Pi Kernel configuration doesn't provide hugepage support.
However, DPDK [requires](http://doc.dpdk.org/guides/linux_gsg/sys_reqs.html)
hugepages for large memory pool allocation used for packet buffers. Please follow
the instructions below to install a pre-build kernel image with enabled hugepage support.

```bash
echo 'deb http://download.opensuse.org/repositories/home:/rstoyanov/Debian_Testing/ /' | sudo tee /etc/apt/sources.list.d/home:rstoyanov.list
curl -fsSL https://download.opensuse.org/repositories/home:rstoyanov/Debian_Testing/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_rstoyanov.gpg > /dev/null
sudo apt-get update
sudo apt-get install p4pi-linux-image-5.10.52-v8
```

## Building kernel

Alternatively, follow these steps to build and install a kernel with hugepages enabled,
[based on this article](https://www.raspberrypi.org/documentation/linux/kernel/building.md).

### Install deps:
```bash
sudo apt-get install git build-essential linux-source bc kmod cpio flex libncurses5-dev libelf-dev libssl-dev
```

Clone the default branch rpi-5.10.y
```
git clone --depth=1 https://github.com/raspberrypi/linux
```

### Configuration
```bash
cd linux
KERNEL=kernel8
make bcm2711_defconfig
#for cross compilation try:
#make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
```

Edit `.config`

```bash
sed -i 's/# CONFIG_HUGETLBFS.*/CONFIG_HUGETLBFS=y/' .config
sed -i 's/# CONFIG_CHECKPOINT_RESTORE.*/CONFIG_CHECKPOINT_RESTORE=y/' .config
sed -i 's/# CONFIG_NAMESPACES.*/CONFIG_NAMESPACES=y/' .config
sed -i 's/# CONFIG_UTS_NS.*/CONFIG_UTS_NS=y/' .config
sed -i 's/# CONFIG_IPC_NS.*/CONFIG_IPC_NS=y/' .config
sed -i 's/# CONFIG_SYSVIPC_SYSCTL.*/CONFIG_SYSVIPC_SYSCTL=y/' .config
sed -i 's/# CONFIG_PID_NS.*/CONFIG_PID_NS=y/' .config
sed -i 's/# CONFIG_NET_NS.*/CONFIG_NET_NS=y/' .config
sed -i 's/# CONFIG_FHANDLE.*/CONFIG_FHANDLE=y/' .config
sed -i 's/# CONFIG_EVENTFD.*/CONFIG_EVENTFD=y/' .config
sed -i 's/# CONFIG_EPOLL.*/CONFIG_EPOLL=y/' .config
sed -i 's/# CONFIG_UNIX_DIAG.*/CONFIG_UNIX_DIAG=y/' .config
sed -i 's/# CONFIG_INET_DIAG.*/CONFIG_INET_DIAG=y/' .config
sed -i 's/# CONFIG_INET_UDP_DIAG.*/CONFIG_INET_UDP_DIAG=y/' .config
sed -i 's/# CONFIG_PACKET_DIAG.*/CONFIG_PACKET_DIAG=y/' .config
sed -i 's/# CONFIG_NETLINK_DIAG.*/CONFIG_NETLINK_DIAG=y/' .config
sed -i 's/# CONFIG_NETFILTER_XT_MARK.*/CONFIG_NETFILTER_XT_MARK=y/' .config
sed -i 's/# CONFIG_TUN.*/CONFIG_TUN=y/' .config
sed -i 's/# CONFIG_INOTIFY_USER.*/CONFIG_INOTIFY_USER=y/' .config
sed -i 's/# CONFIG_FANOTIFY.*/CONFIG_FANOTIFY=y/' .config
sed -i 's/# CONFIG_MEMCG.*/CONFIG_MEMCG=y/' .config
sed -i 's/# CONFIG_CGROUP_DEVICE.*/CONFIG_CGROUP_DEVICE=y/' .config
sed -i 's/# CONFIG_MACVLAN.*/CONFIG_MACVLAN=y/' .config
sed -i 's/# CONFIG_BRIDGE.*/CONFIG_BRIDGE=y/' .config
sed -i 's/# CONFIG_BINFMT_MISC.*/CONFIG_BINFMT_MISC=y/' .config
sed -i 's/# CONFIG_IA32_EMULATION.*/CONFIG_IA32_EMULATION=y/' .config
sed -i 's/# CONFIG_USERFAULTFD.*/CONFIG_USERFAULTFD=y/' .config
sed -i 's/# CONFIG_MEM_SOFT_DIRTY.*/CONFIG_MEM_SOFT_DIRTY=y/' .config
sed -i 's/# CONFIG_NET_CLS_BPF.*/CONFIG_NET_CLS_BPF=m/' .config
```

### Build deb packages

```bash
make -j`nproc` \
    KERNEL=kernel8 \
    KBUILD_BUILD_USER="<name>" \
    KBUILD_DEBARCH=arm64 \
    DEBEMAIL="<email address>" \
    KDEB_CHANGELOG_DIST=bullseye \
    KDEB_SOURCENAME=p4pi-kernel \
    ARCH=arm64 \
    bindeb-pkg
```

### Build source deb package (without signature)

Make sure to add the following packages in `Build-Depends` list of `debian/control`:
- build-essential
- linux-libc-dev

```
dpkg-buildpackage --unsigned-source --unsigned-changes --build=source
```

### Allocation at boot time with kernel params if needed

```
default_hugepagesz=1G hugepagesz=1G hugepages=2
```