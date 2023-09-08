#!/bin/bash
set -x

cont=podman

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
        -v "$(pwd)"/container-boot.d:/container-boot.d \
        -v "$(pwd)"/container-stop.d:/container-stop.d \
        -v "$(pwd)"/buildroot:/buildroot \
        -v "$(pwd)"/../:/zfsbootmenu \
        -v "$(pwd)"/output:/build/build \
        -v /dev/net/tun:/dev/net/tun \
        --cap-add=NET_ADMIN  \
        zbuilder -- -d
}
# build an image - extra debug info
build-debug() {
    $cont run --rm -it \
        -v "$(pwd)"/container-boot.d:/container-boot.d \
        -v "$(pwd)"/container-stop.d:/container-stop.d \
        -v "$(pwd)"/buildroot:/buildroot \
        -v "$(pwd)"/../:/zfsbootmenu \
        -v "$(pwd)"/output:/build/build \
        -v /dev/net/tun:/dev/net/tun \
        --cap-add=NET_ADMIN  \
        zbuilder -- -dd -d
}
# build an image - shell into builder image - you issue /build-init.sh to build
build-shell() {
    $cont run --rm -it \
        -v "$(pwd)"/container-boot.d:/container-boot.d \
        -v "$(pwd)"/container-stop.d:/container-stop.d \
        -v "$(pwd)"/buildroot:/buildroot \
        -v "$(pwd)"/../:/zfsbootmenu \
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
