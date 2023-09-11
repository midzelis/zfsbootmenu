#!/bin/bash
set -x

mkdir -p "$(pwd)"/output

cont=docker

start-podman() {
    podman machine start
}

# https://unix.stackexchange.com/questions/530674/qemu-doesnt-respect-the-boot-order-when-booting-with-uefi-ovmf

# This builds the builder image - do this first (one of -debian, -void)
init-debian() {
    $cont build -f Dockerfile -t zbuilder .
}
init-void() {
    $cont build -f Dockerfile.void -t zbuilder .
}
# build an image - normal
build() {
    set -x
    $cont run --rm -it \
        -v "$(pwd)"/build-start.sh:/container-boot.d/build-start.sh \
        -v "$(pwd)"/build-stop.sh:/container-stop.d/build-stop.sh  \
        -v "$(pwd)"/../../:/zfsbootmenu \
        -v "$(pwd)"/output:/build/build \
        -v /dev/net/tun:/dev/net/tun \
        --cap-add=NET_ADMIN  \
        zbuilder -- -d
    mv output/boot-vfs.raw /LUNA/ALPHA/PVE_VIRTUAL_MACHINES/NFS_DISKS/images/2200/vm-2200-disk-0.raw
}
# build an image - extra debug info
build-debug() {
    $cont run --rm -it \
        -v "$(pwd)"/build-start.sh:/container-boot.d/build-start.sh \
        -v "$(pwd)"/build-stop.sh:/container-stop.d/build-stop.sh  \
        -v "$(pwd)"/../../:/zfsbootmenu \
        -v "$(pwd)"/output:/build/build \
        -v /dev/net/tun:/dev/net/tun \
        --cap-add=NET_ADMIN  \
        zbuilder -- -dd -d
}
# build an image - shell into builder image - you issue /build-init.sh to build
build-shell() {
    $cont run --rm -it \
        -v "$(pwd)"/build-start.sh:/container-boot.d/build-start.sh \
        -v "$(pwd)"/build-stop.sh:/container-stop.d/build-stop.sh  \
        -v "$(pwd)"/../../:/zfsbootmenu \
        -v "$(pwd)"/output:/build/build \
        -v /dev/net/tun:/dev/net/tun \
        --cap-add=NET_ADMIN  \
        --entrypoint=/bin/bash \
        zbuilder 
}

cmd=${1:-}
kind=${2:-}
cmds=(init-debian init-void build build-debug build-shell)
if [ ! -z $cmd ] && [[ " ${cmds[*]} " =~ " $cmd " ]]; then
    $cmd
    exit $?
fi
tmp=${cmds[@]}
echo "Enter a command like ${tmp// /, }"
