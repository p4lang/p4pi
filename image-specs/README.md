# P4Pi image specs

This subfolder contains the files with which the P4Pi images have been built.

The build scripts are based on the tools used for
[Raspberry Pi OS](https://github.com/RPi-Distro/Pi-gen)
(previously known as Raspbian) and
[Debian Raspberry Pi image specs](https://salsa.debian.org/raspi-team/image-specs.git).

## Docker Build

Docker can be used to perform the build inside a container. This partially
isolates the build from the host system, and allows using the script on
non-debian based systems (e.g. Fedora Linux).

Linux is able execute binaries from other architectures, allowing to build
the image on an x86_64 system. This requires support from the `binfmt_misc`
kernel module and to register `binfmt_misc` entries.

```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

To build:

```bash
./build-docker.sh
```

If everything goes well, your finished image will be in the `deploy/` folder.
You can then remove the build container with `docker rm -v pigen_work`

If something breaks along the line, you can edit the corresponding scripts, and
continue:

```bash
CONTINUE=1 ./build-docker.sh
```

To examine the container after a failure you can enter a shell within it using:

```bash
sudo docker run -it --privileged --volumes-from=pigen_work pi-gen /bin/bash
```

After successful build, the build container is by default removed. This may be
undesired when making incremental changes to a customized build. To prevent the
build script from remove the container add

```bash
PRESERVE_CONTAINER=1 ./build-docker.sh
```

Additional arguments for the `docker run` command may be specified in the `PIGEN_DOCKER_OPTS` environment variable.
The `--name` and `--privileged` options are already set by the script and should not be redefined.

```bash
PIGEN_DOCKER_OPTS="-e DEPLOY_ZIP=0" ./build-docker.sh
```

### Stage specification

If you wish to build up to a specified stage, place an empty file named `SKIP` in each of the `./stage` directories you wish not to include.

Then add an empty file named `SKIP_IMAGES` to `./stage4` and `./stage5` (if building up to stage 2) or
to `./stage2` (if building a minimal system).

```bash
touch stage0/00-configure/SKIP

CONTINUE=1 ./build-docker.sh
```

## Installing the image onto the Raspberry Pi

We recommend using [Raspberry Pi Imager](https://github.com/raspberrypi/rpi-imager/releases) - alternatively, you can install the image as follows.

1. Plug an SD card which you would like to entirely overwrite into your SD card reader.

2. Assuming your SD card reader provides the device `/dev/mmcblk0`, copy the
image onto the SD card:

**Beware** If you choose the wrong device, you might overwrite important parts
 of your system. Double check it's the correct device!

```shell
sudo dd if=raspi_3.img of=/dev/mmcblk0 bs=64k oflag=dsync status=progress
```

3. Then, plug the SD card into the Raspberry Pi, and power it up.

