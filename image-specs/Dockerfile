ARG BASE_IMAGE=docker.io/library/debian:buster
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y -qq --no-install-recommends \
        git \
        parted \
        quilt \
        coreutils \
        qemu-user-static \
        debootstrap \
        zerofree \
        zip \
        dosfstools \
        libarchive-tools \
        libcap2-bin \
        rsync \
        grep \
        udev \
        tar \
        xz-utils \
        curl \
        xxd \
        file \
        kmod \
        bc\
        binfmt-support \
        ca-certificates \
        qemu-utils \
        kpartx

COPY . /pi-gen/

VOLUME [ "/pi-gen/work", "/pi-gen/deploy"]
