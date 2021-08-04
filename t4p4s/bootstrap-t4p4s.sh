
IS_SCRIPT_SOURCED=no
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && IS_SCRIPT_SOURCED=yes

# Highlight colours
cc="\033[1;33m"     # yellow
ee="\033[1;31m"     # red
nn="\033[0m"

if [ $# -gt 0 ] && [ "$1" == "showenvs" ]; then
    escape_char=$(printf '\033')
    colours=([0]="${escape_char}[1;32m" [1]="${escape_char}[1;33m" [2]="${escape_char}[1;31m")
    nn="${escape_char}[0m"

    echo "The ${colours[0]}$0$nn script uses the following ${colours[1]}default values$nn for ${colours[0]}environment variables$nn."
    cat "$0" | grep -e '\([A-Z0-9_]*\)=[$][{]\1-'| sed "s/[ ]*export//" | sed "s/[ ]*\([^=]*\)=[$][{]\1-\(.*\)[}]$/    ${colours[0]}\1$nn=${colours[1]}\2$nn/" | sort
    echo "Override them like this to customise the script's behaviour."
    echo "    ${colours[0]}MAX_MAKE_JOBS$nn=${colours[1]}8$nn ${colours[0]}T4P4S_CC$nn=${colours[1]}clang$nn ${colours[0]}$0$nn"
    [ "$IS_SCRIPT_SOURCED" == "yes" ] && return
    exit
fi

if [ "`cat /etc/os-release | grep ID_LIKE= | cut -d= -f2`" == "ubuntu" ]; then
    MIN_UBUNTU_VSN=20

    UBUNTU_VSN=`cat /etc/os-release | grep VERSION_ID= | cut -d'"' -f2 | cut -d'.' -f1`
    [ $UBUNTU_VSN -lt $MIN_UBUNTU_VSN ] && echo -e "${cc}Warning$nn: Ubuntu version lower than minimum supported ($cc$MIN_UBUNTU_VSN$nn), installation may fail" && echo
fi

INST_MB_DPDK=420
INST_MB_PROTOBUF=1500
INST_MB_P4C=1700
INST_MB_GRPC=1400
INST_MB_PI=640
INST_MB_T4P4S_EXAMPLES=4000

P4C_APPROX_KB_PER_JOB=1200


WORKDIR=`pwd`
LOGDIR=`pwd`/log
T4P4S_BUILD_DIR=${T4P4S_BUILD_DIR-"./build"}

SYSTEM_THREAD_COUNT=`nproc --all`

MAX_MAKE_JOBS=${MAX_MAKE_JOBS-$SYSTEM_THREAD_COUNT}
FRESH=${FRESH-yes}
CLEANUP=${CLEANUP-yes}
USE_OPTIONAL_PACKAGES=${USE_OPTIONAL_PACKAGES-yes}
PARALLEL_INSTALL=${PARALLEL_INSTALL-yes}

INSTALL_STAGE1_PACKAGES=${INSTALL_STAGE1_PACKAGES-yes}
INSTALL_STAGE2_DPDK=${INSTALL_STAGE2_DPDK-yes}
INSTALL_STAGE3_PROTOBUF=${INSTALL_STAGE3_PROTOBUF-yes}
INSTALL_STAGE4_P4C=${INSTALL_STAGE4_P4C-yes}
INSTALL_STAGE5_GRPC=${INSTALL_STAGE5_GRPC-yes}
INSTALL_STAGE6_T4P4S=${INSTALL_STAGE6_T4P4S-yes}

PROTOBUF_USE_RC=${PROTOBUF_USE_RC-no}
TODAY=`date +%F`
P4C_COMMIT_DATE=${P4C_COMMIT_DATE-$TODAY}

T4P4S_ENVVAR_FILE=t4p4s_envvars.sh

REPO_PATH_protobuf=${REPO_PATH_protobuf-"https://github.com/google/protobuf"}
REPO_PATH_p4c=${REPO_PATH_p4c-"https://github.com/p4lang/p4c"}
REPO_PATH_grpc=${REPO_PATH_grpc-"https://github.com/grpc/grpc"}
REPO_PATH_PI=${REPO_PATH_PI-"https://github.com/p4lang/PI"}
REPO_PATH_P4Runtime_GRPCPP=${REPO_PATH_P4Runtime_GRPCPP-"https://github.com/P4ELTE/P4Runtime_GRPCPP"}
REPO_PATH_t4p4s=${REPO_PATH_t4p4s-"https://github.com/P4ELTE/t4p4s"}

GRPC_TAG=${GRPC_TAG-"master"}

echo -e "System has $cc`nproc --all`$nn cores; will use $cc$MAX_MAKE_JOBS$nn jobs"

echo Requesting root access...
sudo echo -n ""
if [ $? -ne 0 ]; then
    echo -e "Root access ${cc}not granted$nn, exiting"
    [ "$IS_SCRIPT_SOURCED" == "yes" ] && return 1
    exit 1
fi
echo Root access granted, starting...

if [ "$FRESH" == "yes" ]; then
    unset DPDK_VSN
    unset RTE_SDK
    unset RTE_TARGET
    unset P4C
fi

if [ "$CLEANUP" == "yes" ]; then
    CLEANUP_DIR=cleanup_archive`date +%Y%m%d-%H%M`

    mkdir -p $CLEANUP_DIR

    sudo mv --backup=numbered dpdk* $CLEANUP_DIR/ 2>/dev/null
    mv --backup=numbered log $CLEANUP_DIR/ 2>/dev/null
    mv --backup=numbered protobuf $CLEANUP_DIR/ 2>/dev/null
    mv --backup=numbered p4c $CLEANUP_DIR/ 2>/dev/null
    mv --backup=numbered grpc $CLEANUP_DIR/ 2>/dev/null
    mv --backup=numbered PI $CLEANUP_DIR/ 2>/dev/null
    mv --backup=numbered P4Runtime_GRPCPP $CLEANUP_DIR/ 2>/dev/null
    mv --backup=numbered t4p4s* $CLEANUP_DIR/ 2>/dev/null
    mv --backup=numbered ${T4P4S_ENVVAR_FILE} $CLEANUP_DIR/ 2>/dev/null

    CLEANUP_SIZE=`du -hcs $CLEANUP_DIR | head -1 | cut -d$'\t' -f1`

    [ "$(ls -A $CLEANUP_DIR)" ] && echo -e "Moved ${cc}${CLEANUP_SIZE}B$nn of previous content to backup folder ${cc}$CLEANUP_DIR$nn" || rmdir $CLEANUP_DIR
fi

APPROX_INSTALL_MB=0
[ "$INSTALL_STAGE2_DPDK" == "yes" ] && APPROX_INSTALL_MB=$(($APPROX_INSTALL_MB+INST_MB_DPDK))
[ "$INSTALL_STAGE3_PROTOBUF" == "yes" ] && APPROX_INSTALL_MB=$(($APPROX_INSTALL_MB+INST_MB_PROTOBUF))
[ "$INSTALL_STAGE4_P4C" == "yes" ] && APPROX_INSTALL_MB=$(($APPROX_INSTALL_MB+INST_MB_P4C))
[ "$INSTALL_STAGE5_GRPC" == "yes" ] && APPROX_INSTALL_MB=$(($APPROX_INSTALL_MB+INST_MB_GRPC+INST_MB_PI))

APPROX_TOTAL_MB=$(($APPROX_INSTALL_MB+INST_MB_T4P4S_EXAMPLES))
FREE_MB="`df --output=avail -m . | tail -1 | tr -d '[:space:]'`"

SKIP_CHECK=${SKIP_CHECK-no}


find_tool() {
    SEP=$1
    shift
    DEFAULT_TOOL=$1
    T4P4S_TOOL_DIR="${T4P4S_BUILD_DIR}/tools"
    mkdir -p "${T4P4S_TOOL_DIR}"
    TOOL_FILE="${T4P4S_TOOL_DIR}/tool.${DEFAULT_TOOL}.txt"
    [ -f "${TOOL_FILE}" ] && cat "${TOOL_FILE}" && return
    for tool in $*; do
        for candidate in `apt-cache search --names-only "^${tool}[\.\-]?[0-9]*$" | tr "." "-" | cut -f 1 -d " " | sort -t "-" -k 2,2nr | tr "\n" " " | tr "-" "$SEP"`; do
            which $candidate >/dev/null
            [ $? -eq 0 ] && echo $candidate | tee "${TOOL_FILE}" && return
        done
        which $tool >/dev/null
        [ $? -eq 0 ] && echo $tool | tee "${TOOL_FILE}" && return
    done
    exit_on_error "Cannot not find $(cc 2)$tool$nn tool"
}

PYTHON3=${PYTHON3-$(find_tool "." python3)}
T4P4S_CC=${T4P4S_CC-$(find_tool "-" clang gcc)}
if [[ ! "$T4P4S_CC" =~ "clang" ]]; then
    # note: when using gcc, only lld seems to be supported, not lld-VSN
    T4P4S_LD=${T4P4S_LD-$(find_tool lld bfd gold)}
else
    T4P4S_LD=${T4P4S_LD-$(find_tool "-" lld bfd gold)}
fi

if [ "$PYTHON3" == "" ]; then
    echo -e "Could not find appropriate Python 3 version, exiting"
    [ "$IS_SCRIPT_SOURCED" == "yes" ] && return 1
    exit 1
fi

echo -e "Using CC=${cc}$T4P4S_CC$nn, CXX=${cc}$T4P4S_CXX$nn, LD=${cc}$T4P4S_LD$nn, PYTHON3=${cc}${PYTHON3}$nn"

if [ "$SKIP_CHECK" == "no" ] && [ "$FREE_MB" -lt "$APPROX_INSTALL_MB" ]; then
    echo -e "Bootstrapping requires approximately $cc$APPROX_INSTALL_MB MB$nn of free space"
    echo -e "You seem to have $cc$FREE_MB MB$nn of free space on the current drive"
    echo -e "To force installation, run ${cc}SKIP_CHECK=1 . ./bootstrap.sh$nn"
    [ "$IS_SCRIPT_SOURCED" == "yes" ] && return 1
    exit 1
else
    echo -e "Installation will use approximately $cc$APPROX_INSTALL_MB MB$nn"
fi

if [ "$FREE_MB" -lt "$APPROX_TOTAL_MB" ]; then
    echo -e "Bootstrapping and then compiling all examples requires approximately $cc$APPROX_TOTAL_MB MB$nn of free space"
    echo -e "${cc}Warning$nn: you seem to have $cc$FREE_MB MB$nn of free space on the current drive"
fi



function logfile() {
    case "$1" in
        "curl-git")             LOG_STAGE="01";;
        "apt")                  LOG_STAGE="02";;
        "get-dpdk")             LOG_STAGE="03";;
        "get-protobuf")         LOG_STAGE="04";;
        "get-p4c")              LOG_STAGE="05";;
        "get-grpc")             LOG_STAGE="06";;
        "get-PI")               LOG_STAGE="07";;
        "get-P4Runtime_GRPCPP") LOG_STAGE="08";;
        "get-t4p4s")            LOG_STAGE="09";;
        "python3")              LOG_STAGE="10";;
        "dpdk")                 LOG_STAGE="20";;
        "protobuf")             LOG_STAGE="30";;
        "p4c")                  LOG_STAGE="40";;
        "grpc")                 LOG_STAGE="50";;
        "PI")                   LOG_STAGE="51";;
        "P4Runtime_GRPCPP")     LOG_STAGE="52";;
        "t4p4s")                LOG_STAGE="60";;
        *)                      LOG_STAGE="99";;
    esac
    echo "$LOGDIR/${LOG_STAGE}_$1$2.txt"
}

mkdir -p "$LOGDIR"

if [ ! `which curl` ] || [ ! `which git` ]; then
    echo -e "Installing ${cc}curl$nn and ${cc}git$nn"
    sudo apt-get -y install curl git >$(logfile "curl-git") 2>&1
fi

if [ "$INSTALL_STAGE3_PROTOBUF" == "yes" ]; then
    if [ "$PROTOBUF_TAG" == "" ]; then
        [ "$PROTOBUF_USE_RC" != "yes" ] && NEWEST_PROTOBUF_TAG=`git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' $REPO_PATH_protobuf | grep -ve "[-]rc" | tail -1 | cut -f3 -d/`
        [ "$PROTOBUF_USE_RC" == "yes" ] && NEWEST_PROTOBUF_TAG=`git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' $REPO_PATH_protobuf                    | tail -1 | cut -f3 -d/`
    fi
    PROTOBUF_TAG=${PROTOBUF_TAG-$NEWEST_PROTOBUF_TAG}

    echo -e "Using ${cc}protobuf$nn tag $cc$PROTOBUF_TAG$nn"
fi

if [ "$INSTALL_STAGE2_DPDK" == "yes" ]; then
    if [ "$DPDK_VSN" != "" ]; then
        echo -e "Using ${cc}user set DPDK version$nn \$DPDK_VSN=$cc${DPDK_VSN}$nn"
    else
        # Get the most recent DPDK version
        vsn=`curl -s "https://fast.dpdk.org/rel/" --list-only \
            | grep ".tar.xz" \
            | sed -e "s/^[^>]*>dpdk-\([0-9.]*\)\.tar\.xz[^0-9]*\([0-9]\{2\}\)-\([a-zA-Z]\{3\}\)-\([0-9]\{4\}\) \([0-9]\{2\}\):\([0-9]\{2\}\).*$/\4 \3 \2 \5 \6 \1/g" \
            | sed -e "s/ \([0-9]\{2\}\)[.]\([0-9]\{2\}\)$/ \1.\2.-1/g" \
            | tr '.' ' ' \
            | sort -k6,6n -k7,7n -k8,8n -k1,1 -k2,2M -k3,3 -k4,4 -k5,5 \
            | tac \
            | cut -d" " -f 6- \
            | sed -e "s/^\([0-9\-]*\) \([0-9\-]*\) \([0-9\-]*\)$/\3 \1.\2/g" \
            | uniq -f1 \
            | head -1`

        vsn=($vsn)

        DPDK_NEWEST_VSN="${vsn[1]}"
        DPDK_VSN=${DPDK_VSN-$DPDK_NEWEST_VSN}
        echo -e "Using ${cc}DPDK$nn version $cc${DPDK_VSN}$nn"
    fi

    DPDK_FILEVSN="$DPDK_VSN"
    [ "${vsn[0]}" != "-1" ] && DPDK_FILEVSN="$DPDK_VSN.${vsn[0]}"
fi


if [ "$RTE_TARGET" != "" ]; then
    echo -e "Using ${cc}DPDK target$nn RTE_TARGET=$cc$RTE_TARGET$nn"
else
    export RTE_TARGET=${RTE_TARGET-"x86_64-native-linuxapp-$T4P4S_CC"}
fi

echo -e "Using ${cc}p4c$nn commit from ${cc}$P4C_COMMIT_DATE$nn"


PKGS_PYTHON=""
PKGS_LIB="libtool libgc-dev libprotobuf-dev libprotoc-dev libnuma-dev libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev"
PKGS_MAKE="ninja-build automake bison flex cmake ccache lld pkg-config"
PKGS_GRPC=""
[ "$INSTALL_STAGE5_GRPC" == "yes" ] && PKGS_GRPC="libjudy-dev libssl-dev libboost-thread-dev libboost-dev libboost-system-dev libboost-thread-dev libtool-bin"
REQUIRED_PACKAGES="$PKGS_PYTHON $PKGS_LIB $PKGS_MAKE $PKGS_GRPC g++ tcpdump"
PIP_PACKAGES="meson pyelftools pybind11 pysimdjson ipaddr scapy dill setuptools"
if [ "$USE_OPTIONAL_PACKAGES" == "yes" ]; then
    OPT_PACKAGES=""
    PIP_PACKAGES="$PIP_PACKAGES backtrace ipdb termcolor colored pyyaml ujson ruamel.yaml"
fi

T4P4S_DIR=${T4P4S_DIR-t4p4s}
[ $# -gt 0 ] && T4P4S_DIR="t4p4s-$1" && T4P4S_CLONE_OPT="$T4P4S_DIR -b $1" && echo -e "Using the $cc$1$nn branch of T4P4S"


LOCAL_REPO_CACHE=${LOCAL_REPO_CACHE-}

if [ "$LOCAL_REPO_CACHE" != "" ]; then
    if [ ! -d "$LOCAL_REPO_CACHE" ]; then
        echo -e "The local repo cache ${cc}$LOCAL_REPO_CACHE$nn is not a directory, exiting"
        [ "$IS_SCRIPT_SOURCED" == "yes" ] && return 1
        exit 1
    fi

    echo -e "Using local repo cache $cc$LOCAL_REPO_CACHE$nn"

    [ ! -d "$LOCAL_REPO_CACHE/protobuf" ] && echo -e "${cc}Warning$nn: \$LOCAL_REPO_CACHE/protobuf$nn is not a directory, installation will use the remote repo"
    [   -d "$LOCAL_REPO_CACHE/protobuf" ] && REPO_PATH_protobuf="$LOCAL_REPO_CACHE/protobuf"

    [ ! -d "$LOCAL_REPO_CACHE/p4c" ] && echo -e "${cc}Warning$nn: \$LOCAL_REPO_CACHE/p4c$nn is not a directory, installation will use the remote repo"
    [   -d "$LOCAL_REPO_CACHE/p4c" ] && REPO_PATH_p4c="$LOCAL_REPO_CACHE/p4c"

    [ ! -d "$LOCAL_REPO_CACHE/grpc" ] && echo -e "${cc}Warning$nn: \$LOCAL_REPO_CACHE/grpc$nn is not a directory, installation will use the remote repo"
    [   -d "$LOCAL_REPO_CACHE/grpc" ] && REPO_PATH_grpc="$LOCAL_REPO_CACHE/grpc"

    [ ! -d "$LOCAL_REPO_CACHE/PI" ] && echo -e "${cc}Warning$nn: \$LOCAL_REPO_CACHE/PI$nn is not a directory, installation will use the remote repo"
    [   -d "$LOCAL_REPO_CACHE/PI" ] && REPO_PATH_PI="$LOCAL_REPO_CACHE/PI"

    [ ! -d "$LOCAL_REPO_CACHE/P4Runtime_GRPCPP" ] && echo -e "${cc}Warning$nn: \$LOCAL_REPO_CACHE/P4Runtime_GRPCPP$nn is not a directory, installation will use the remote repo"
    [   -d "$LOCAL_REPO_CACHE/P4Runtime_GRPCPP" ] && REPO_PATH_P4Runtime_GRPCPP="$LOCAL_REPO_CACHE/P4Runtime_GRPCPP"

    [ ! -d "$LOCAL_REPO_CACHE/t4p4s" ] && echo -e "${cc}Warning$nn: \$LOCAL_REPO_CACHE/t4p4s$nn is not a directory, installation will use the remote repo"
    [   -d "$LOCAL_REPO_CACHE/t4p4s" ] && REPO_PATH_t4p4s="$LOCAL_REPO_CACHE/t4p4s"
fi


echo -e "-------- Configuration done, installing (see details under ${cc}$LOGDIR$nn)"
echo -e "-------- Installation may take several minutes for each of the following libraries"

# Download libraries
if [ "$INSTALL_STAGE1_PACKAGES" == "yes" ]; then
    sudo apt-get update >$(logfile "apt") 2>&1 && sudo apt-get -y install $REQUIRED_PACKAGES $OPT_PACKAGES >>$(logfile "apt") 2>&1 &
    WAITPROC_APTGET="$!"
    [ "$PARALLEL_INSTALL" != "yes" ] && wait "$WAITPROC_APTGET" >/dev/null 2>&1
fi

if [ "$INSTALL_STAGE2_DPDK" == "yes" ]; then
    [ ! -d "dpdk-${DPDK_VSN}" ] && wget -q -o /dev/null http://fast.dpdk.org/rel/dpdk-$DPDK_FILEVSN.tar.xz >$(logfile "get-dpdk") 2>&1 && tar xJf dpdk-$DPDK_FILEVSN.tar.xz && rm dpdk-$DPDK_FILEVSN.tar.xz &
    WAITPROC_DPDK="$!"
    [ "$PARALLEL_INSTALL" != "yes" ] && wait "$WAITPROC_DPDK" >/dev/null 2>&1
fi

if [ "$INSTALL_STAGE3_PROTOBUF" == "yes" ]; then
    [ ! -d "protobuf" ] && git clone "$REPO_PATH_protobuf" --no-hardlinks --recursive -b "${PROTOBUF_TAG}" >$(logfile "get-protobuf") 2>&1 &
    WAITPROC_PROTOBUF="$!"
    [ "$PARALLEL_INSTALL" != "yes" ] && wait "$WAITPROC_PROTOBUF" >/dev/null 2>&1
fi

if [ "$INSTALL_STAGE4_P4C" == "yes" ]; then
    [ ! -d "p4c" ] && git clone "$REPO_PATH_p4c" --no-hardlinks --recursive >$(logfile "get-p4c") 2>&1 && cd p4c && git checkout `git rev-list -1 --before="$P4C_COMMIT_DATE" master` >>$(logfile "get-p4c") 2>&1 && git submodule update --init --recursive &
    WAITPROC_P4C="$!"
    [ "$PARALLEL_INSTALL" != "yes" ] && wait "$WAITPROC_P4C" >/dev/null 2>&1
fi

if [ "$INSTALL_STAGE5_GRPC" == "yes" ]; then
    [ ! -d grpc ] && git clone "$REPO_PATH_grpc" --no-hardlinks --recursive -b "${GRPC_TAG}" >$(logfile "get-grpc") 2>&1 &
    WAITPROC_GRPC="$!"
    [ "$PARALLEL_INSTALL" != "yes" ] && wait "$WAITPROC_GRPC" >/dev/null 2>&1

    [ ! -d PI ] && git clone "$REPO_PATH_PI" --no-hardlinks --recursive >$(logfile "get-PI") 2>&1 &
    WAITPROC_PI="$!"
    [ "$PARALLEL_INSTALL" != "yes" ] && wait "$WAITPROC_PI" >/dev/null 2>&1

    [ ! -d P4Runtime_GRPCPP ] && git clone "$REPO_PATH_P4Runtime_GRPCPP" --no-hardlinks --recursive >$(logfile "get-P4Runtime_GRPCPP") 2>&1 &
    WAITPROC_P4Runtime_GRPCPP="$!"
    [ "$PARALLEL_INSTALL" != "yes" ] && wait "$WAITPROC_P4Runtime_GRPCPP" >/dev/null 2>&1
fi

if [ "$INSTALL_STAGE6_T4P4S" == "yes" ]; then
    [ ! -d t4p4s ] && git clone "$REPO_PATH_t4p4s" --no-hardlinks --recursive $T4P4S_CLONE_OPT >$(logfile "get-t4p4s") 2>&1 &
    WAITPROC_T4P4S="$!"
    [ "$PARALLEL_INSTALL" != "yes" ] && wait "$WAITPROC_T4P4S" >/dev/null 2>&1
fi


ctrl_c_handler() {
    kill -9 $WAITPROC_APTGET 2>/dev/null
    kill -9 $WAITPROC_DPDK 2>/dev/null
    kill -9 $WAITPROC_PROTOBUF 2>/dev/null
    kill -9 $WAITPROC_P4C 2>/dev/null
    kill -9 $WAITPROC_GRPC 2>/dev/null
    kill -9 $WAITPROC_PI 2>/dev/null
    kill -9 $WAITPROC_P4Runtime_GRPCPP 2>/dev/null
    kill -9 $WAITPROC_T4P4S 2>/dev/null

    echo "Ctrl-C pressed, exiting"
    exit
}

trap 'ctrl_c_handler' INT

MESONCMD="$PYTHON3 -m mesonbuild.mesonmain"

if [ "$INSTALL_STAGE1_PACKAGES" == "yes" ]; then
    [ "$PARALLEL_INSTALL" == "yes" ] && wait "$WAITPROC_APTGET" >/dev/null 2>&1

    echo -e "Installing ${cc}Python 3 packages$nn"

    sudo ${PYTHON3} -m pip install $PIP_PACKAGES >$(logfile "python3" ".pip") 2>&1

    MESON_VSN=`sudo $MESONCMD --version 2>/dev/null`
    MESON_ERRCODE=$?
    if [ ${MESON_ERRCODE} -ne 0 ]; then
        echo -e "${ee}Could not execute$nn ${cc}meson$nn (error code ${ee}${MESON_ERRCODE}$nn), exiting"
        echo -e "Hint: perhaps ${cc}meson$nn can be found at ${cc}~/.local/bin$nn, if so, consider adding it to your \$PATH"
        [ "$IS_SCRIPT_SOURCED" == "yes" ] && return 1
        exit 1
    fi

    MIN_REQ_MESON_VSN=0.53
    MESON_MIN_VSN=`echo -e "${MIN_REQ_MESON_VSN}\n${MESON_VSN}" | sort -t '.' -k 1,1 -k 2,2 | head -1`
    if [ "$MESON_MIN_VSN" != "$MIN_REQ_MESON_VSN" ]; then
        echo -e "Available ${cc}meson$nn version ${cc}${MESON_VSN}$nn is ${ee}older than the required$nn ${cc}${MIN_REQ_MESON_VSN}$nn, trying to update it"

        sudo ${PYTHON3} -m pip install --force meson >$(logfile "python3" ".pip.meson") 2>&1

        MESON_MIN_VSN=`echo -e "${MIN_REQ_MESON_VSN}\n${MESON_VSN}" | sort -t '.' -k 1,1 -k 2,2 | head -1`
        if [ "$MESON_MIN_VSN" != "$MIN_REQ_MESON_VSN" ]; then
            echo -e "Available ${cc}meson$nn version is still not new enough, exiting"
            [ "$IS_SCRIPT_SOURCED" == "yes" ] && return 1
            exit 1
        fi
    fi
fi

MESON_BUILDTYPE=${MESON_BUILDTYPE-debugoptimized}
MESON_OPTS="-Dbuildtype=${MESON_BUILDTYPE} -Db_pch=true"

if [ "$INSTALL_STAGE2_DPDK" == "yes" ]; then
    ISSKIP=0
    [ "$PARALLEL_INSTALL" == "yes" ] && [ -d "/proc/${WAITPROC_DPDK}" ] 2>/dev/null && echo -ne "Waiting for ${cc}DPDK$nn to download... "
    [ "$PARALLEL_INSTALL" == "yes" ] && wait "$WAITPROC_DPDK" >/dev/null 2>&1

    echo -e "Setting up ${cc}DPDK$nn"

    RTE_SDK_DIR=`ls -d dpdk*$DPDK_FILEVSN* 2>/dev/null`

    if [ $? -ne 0 ]; then
        echo -e "Cannot find extracted DPDK directory under ${cc}`pwd`$nn, exiting"
        [ "$IS_SCRIPT_SOURCED" == "yes" ] && return 1
        exit 1
    fi

    export RTE_SDK="`pwd`/${RTE_SDK_DIR}"

    if [ "$SLIM_INSTALL" == "yes" ]; then
        DPDK_DISABLED_DRIVERS=${DPDK_DISABLED_DRIVERS-baseband/acc100,baseband/fpga_5gnr_fec,baseband/fpga_lte_fec,baseband/null,baseband/turbo_sw,bus/dpaa,bus/fslmc,bus/ifpga,bus/vmbus,common/cpt,common/dpaax,common/iavf,common/octeontx,common/octeontx2,common/qat,common/sfc_efx,compress/octeontx,compress/zlib,crypto/bcmfs,crypto/caam_jr,crypto/ccp,crypto/dpaa2_sec,crypto/dpaa_sec,crypto/nitrox,crypto/null,crypto/octeontx,crypto/octeontx2,crypto/openssl,crypto/scheduler,crypto/virtio,event/dlb,event/dlb2,event/dpaa,event/dpaa2,event/dsw,event/octeontx,event/octeontx2,event/opdl,event/skeleton,event/sw,mempool/bucket,mempool/dpaa,mempool/dpaa2,mempool/octeontx,mempool/octeontx2,mempool/ring,mempool/stack,net/af_packet,net/ark,net/atlantic,net/avp,net/axgbe,net/bnx2x,net/bnxt,net/cxgbe,net/dpaa,net/dpaa2,net/e1000,net/ena,net/enetc,net/enic,net/failsafe,net/bond,net/fm10k,net/hinic,net/hns3,net/i40e,net/iavf,net/ice,net/igc,net/ionic,net/ixgbe,net/kni,net/liquidio,net/memif,net/netvsc,net/nfp,net/null,net/octeontx,net/octeontx2,net/pfe,net/qede,net/ring,net/sfc,net/softnic,net/tap,net/thunderx,net/txgbe,net/vdev_netvsc,net/vhost,net/virtio,net/vmxnet3,raw/dpaa2_cmdif,raw/dpaa2_qdma,raw/ioat,raw/ntb,raw/octeontx2_dma,raw/octeontx2_ep,raw/skeleton,regex/octeontx2,vdpa/ifc}

        # no apps are needed, but there is no convenient option to turn them off
        sed -i -e 's/\(foreach app\)/apps = []\n\1/g' "${RTE_SDK}/app/meson.build"
    else
        DPDK_DISABLED_DRIVERS=${DPDK_DISABLED_DRIVERS-""}
    fi

    cd "$RTE_SDK"
    sudo CC="ccache ${T4P4S_CC}" CFLAGS="$CFLAGS" CC_LD="${T4P4S_LD}" $MESONCMD build $MESON_OPTS -Dtests=false -Ddisable_drivers="$DPDK_DISABLED_DRIVERS" >$(logfile "dpdk" ".meson") 2>&1
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}dpdk$nn/${cc}meson$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && sudo ninja -C build >&2 2>>$(logfile "dpdk" ".ninja")
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}dpdk$nn/${cc}ninja$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && sudo ninja -C build install 2>&1 >>$(logfile "dpdk" ".ninja.install")
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}dpdk$nn/${cc}ninja install$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && sudo ldconfig
    cd "$WORKDIR"
fi

LTO_OPT=""
# LTO_OPT="-flto=thin"

if [ "$INSTALL_STAGE3_PROTOBUF" == "yes" ]; then
    ISSKIP=0
    [ "$PARALLEL_INSTALL" == "yes" ] && [ -d "/proc/${WAITPROC_PROTOBUF}" ] 2>/dev/null && echo -ne "Waiting for ${cc}protobuf$nn to download... "
    [ "$PARALLEL_INSTALL" == "yes" ] && wait "$WAITPROC_PROTOBUF" >/dev/null 2>&1

    echo -e "Setting up ${cc}protobuf$nn"

    mkdir -p protobuf/cmake/build
    cd protobuf/cmake/build
    cmake .. -DCMAKE_C_FLAGS="$CFLAGS -fPIC ${LTO_OPT}" -DCMAKE_CXX_FLAGS="$CFLAGS -Wno-cpp -fPIC ${LTO_OPT}" -DCMAKE_C_COMPILER="${T4P4S_CC}" -DCMAKE_CXX_COMPILER="${T4P4S_CXX}" -GNinja  -DBUILD_TESTS=OFF -DBUILD_CONFORMANCE=OFF -DBUILD_EXAMPLES=OFF -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_CONFORMANCE=OFF -Dprotobuf_BUILD_EXAMPLES=OFF >$(logfile "protobuf" ".cmake") 2>&1
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}protobuf$nn/${cc}cmake$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && sudo ninja -j ${MAX_MAKE_JOBS} >&2 2>>$(logfile "protobuf" ".ninja")
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}protobuf$nn/${cc}ninja$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && sudo ninja install -j ${MAX_MAKE_JOBS} 2>&1 >>$(logfile "protobuf" ".ninja.install")
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}protobuf$nn/${cc}ninja install$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && sudo ldconfig
    cd "$WORKDIR"
fi

if [ "$INSTALL_STAGE4_P4C" == "yes" ]; then
    ISSKIP=0
    [ "$PARALLEL_INSTALL" == "yes" ] && [ -d "/proc/${WAITPROC_P4C}" ] 2>/dev/null && echo -ne "Waiting for ${cc}p4c$nn to download... "
    [ "$PARALLEL_INSTALL" == "yes" ] && wait "$WAITPROC_P4C" >/dev/null 2>&1

    echo -e "Setting up ${cc}p4c$nn"

    export P4C=`pwd`/p4c

    mkdir p4c/build
    cd p4c/build
    sed -i 's/-fuse-ld=gold/-fuse-ld=${T4P4S_LD}/g' ../CMakeLists.txt
    cmake .. -DCMAKE_C_FLAGS="${P4C_CFLAGS} -fPIC" -DCMAKE_CXX_FLAGS="${P4C_CFLAGS} -Wno-cpp -fPIC" -DCMAKE_C_COMPILER="gcc" -DCMAKE_CXX_COMPILER="g++" -GNinja  -DENABLE_P4TEST=ON -DENABLE_EBPF=OFF -DENABLE_UBPF=OFF -DENABLE_P4C_GRAPHS=OFF -DENABLE_GTESTS=OFF >$(logfile "p4c" ".ninja") 2>&1
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}p4c$nn/${cc}cmake$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"

    # free up as much memory as possible
    sudo sh -c 'echo 3 >/proc/sys/vm/drop_caches'

    MEM_FREE_KB=`cat /proc/meminfo | grep MemFree | grep -Eo '[0-9]+'`
    JOBS_BY_MEM_FREE=$(($MEM_FREE_KB / $P4C_APPROX_KB_PER_JOB / 1024))
    MAX_MAKE_JOBS_P4C=$(($JOBS_BY_MEM_FREE<$MAX_MAKE_JOBS ? $JOBS_BY_MEM_FREE : $MAX_MAKE_JOBS))
    MAX_MAKE_JOBS_P4C=$(($MAX_MAKE_JOBS_P4C <= 0 ? 1 : $MAX_MAKE_JOBS_P4C))
    echo -e "Will use $cc$MAX_MAKE_JOBS_P4C$nn for ${cc}p4c$nn compilation"

    [ $ISSKIP -ne 1 ] && sudo ninja -j ${MAX_MAKE_JOBS_P4C} >&2 2>>$(logfile "p4c" ".ninja")
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}p4c$nn/${cc}ninja$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && sudo ninja install -j ${MAX_MAKE_JOBS_P4C} 2>&1 >>$(logfile "p4c" ".ninja.install")
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}p4c$nn/${cc}ninja install$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    cd "$WORKDIR"
fi


if [ "$INSTALL_STAGE5_GRPC" == "yes" ]; then
    [ "$PARALLEL_INSTALL" == "yes" ] && [ -d "/proc/${WAITPROC_GRPC}" ] 2>/dev/null && echo -ne "Waiting for ${cc}grpc$nn to download... "
    [ "$PARALLEL_INSTALL" == "yes" ] && wait "$WAITPROC_GRPC" >/dev/null 2>&1
    echo -e "Setting up ${cc}grpc$nn"
    mkdir -p grpc/build
    cd grpc/build
    ISSKIP=0
    cmake .. -DCMAKE_C_FLAGS="$CFLAGS -fPIC" -DCMAKE_CXX_FLAGS="$CFLAGS -Wno-cpp -fPIC" -DCMAKE_C_COMPILER="${T4P4S_CC}" -DCMAKE_CXX_COMPILER="${T4P4S_CXX}" -GNinja >$(logfile "grpc" ".cmake") 2>&1
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}grpc$nn/${cc}cmake$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && ninja >&2 2>>$(logfile "grpc" ".ninja")
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}grpc$nn/${cc}ninja$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && sudo ninja install 2>&1 >>$(logfile "grpc" ".ninja.install")
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}grpc$nn/${cc}ninja install$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    cd "$WORKDIR"

    [ "$PARALLEL_INSTALL" == "yes" ] && [ -d "/proc/${WAITPROC_PI}" ] 2>/dev/null && echo -ne "Waiting for ${cc}PI$nn to download... "
    [ "$PARALLEL_INSTALL" == "yes" ] && wait "$WAITPROC_PI" >/dev/null 2>&1
    echo -e "Setting up ${cc}PI$nn"
    cd PI
    ISSKIP=0
    ./autogen.sh >$(logfile "PI" ".autogen") 2>&1
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}pi$nn/${cc}autogen$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && CC="ccache ${T4P4S_CC}" CC_LD="${T4P4S_LD}" CXX="${T4P4S_CXX}" ./configure --with-proto >>$(logfile "PI" ".configure") 2>&1
    make -j $MAX_MAKE_JOBS >>$(logfile "PI" ".make") 2>&1
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}pi$nn/${cc}make$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && sudo make install -j $MAX_MAKE_JOBS >>$(logfile "PI" ".make.install") 2>&1
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}pi$nn/${cc}make install$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    cd "$WORKDIR"

    [ "$PARALLEL_INSTALL" == "yes" ] && [ -d "/proc/${WAITPROC_P4Runtime_GRPCPP}" ] 2>/dev/null && echo -ne "Waiting for ${cc}P4Runtime_GRPCPP$nn to download... "
    [ "$PARALLEL_INSTALL" == "yes" ] && wait "$WAITPROC_P4Runtime_GRPCPP" >/dev/null 2>&1
    echo -e "Setting up ${cc}P4Runtime_GRPCPP$nn"
    cd P4Runtime_GRPCPP
    ISSKIP=0
    ./install.sh >$(logfile "P4Runtime_GRPCPP" ".install") 2>&1
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}p4runtime-grpcpp$nn/${cc}install$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    [ $ISSKIP -ne 1 ] && CC="ccache ${T4P4S_CC}" CC_LD="${T4P4S_LD}" CXX="${T4P4S_CXX}" ./compile.sh >>$(logfile "P4Runtime_GRPCPP" ".compile") 2>&1
    ERRCODE=$? && [ $ISSKIP -ne 1 ] && [ $ERRCODE -ne 0 ] && ISSKIP=1 && echo -e "${cc}p4runtime-grpcpp$nn/${cc}compile$nn step ${ee}failed$nn with error code ${ee}$ERRCODE$nn"
    cd "$WORKDIR"
fi



# Save environment config
if [ "$INSTALL_STAGE6_T4P4S" == "yes" ]; then
    [ "$PARALLEL_INSTALL" == "yes" ] && [ -d "/proc/${WAITPROC_T4P4S}" ] 2>/dev/null && echo -ne "Waiting for ${cc}T₄P₄S$nn to download... "
    [ "$PARALLEL_INSTALL" == "yes" ] && wait "$WAITPROC_T4P4S" >/dev/null 2>&1

    DPDK_FILEVSN=${DPDK_FILEVSN-TO_BE_FILLED_BY_USER}
    RTE_SDK=${RTE_SDK-`pwd`/`ls -d dpdk*$DPDK_FILEVSN*/`}

    cat <<EOF >./${T4P4S_ENVVAR_FILE}
export DPDK_VSN=${DPDK_VSN}
export RTE_SDK=${RTE_SDK}
export RTE_TARGET=${RTE_TARGET}
export P4C=`pwd`/p4c
export T4P4S=${T4P4S_DIR}
EOF

    chmod +x ./${T4P4S_ENVVAR_FILE}
    . ./${T4P4S_ENVVAR_FILE}

    echo Environment variable config is done
    echo -e "Environment variable config is saved in ${cc}./${T4P4S_ENVVAR_FILE}$nn"

    ENV_TARGETS="$HOME/.bash_profile $HOME/.bash_login $HOME/.bashrc $HOME/.profile"
    for target in $ENV_TARGETS; do
        [ -a "$target" ] && ENV_TARGET=$target && break
    done

    if [ "$ENV_TARGET" == "" ]; then
        echo -e "Make sure you run ${cc}. ./${T4P4S_ENVVAR_FILE}$nn before you use T4P4S to setup all environment variables"
    else
        # remove all lines containing "t4p4s_environment_variables"
        sed -ni '/${T4P4S_ENVVAR_FILE}/!p' ${ENV_TARGET}

        echo >> ${ENV_TARGET}
        echo ". `pwd`/${T4P4S_ENVVAR_FILE}" >> ${ENV_TARGET}
        echo -e "Environment variable config is ${cc}enabled on login$nn: ${cc}${ENV_TARGET}$nn will run ${cc}${T4P4S_ENVVAR_FILE}$nn"
    fi
fi
