#!/bin/bash -e

TAG=1.20230106

sudo apt-get install \
  git bc bison flex libssl-dev make

git clone -b "${TAG}" --depth=1 https://github.com/raspberrypi/linux
git apply --directory=linux config_p4pi.patch

cd linux
KERNEL=kernel8 make bcm2711_defconfig

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

yes | make -j`nproc` \
    KERNEL=kernel8 \
    KBUILD_BUILD_USER="<name>" \
    KBUILD_DEBARCH=arm64 \
    DEBEMAIL="<email address>" \
    KDEB_CHANGELOG_DIST=bullseye \
    KDEB_SOURCENAME=p4pi-kernel \
    ARCH=arm64 \
    LOCALVERSION=-p4pi \
    deb-pkg
