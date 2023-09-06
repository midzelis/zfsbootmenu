#!/bin/bash

# This builds the builder image - do this first (one of -debian, -void)
build_builder-debian() {
    docker build -f Dockerfile -t zbuilder .
}
build_builder-void() {
    docker build -f Dockerfile.void -t zbuilder .
}
# build an image - normal
build() {
    set -x
    docker run --rm -it \
        -v "$(pwd)"/container-boot.d:/container-boot.d \
        -v "$(pwd)"/buildroot:/buildroot \
        -v "$(pwd)"/../:/zfsbootmenu \
        -v "$(pwd)"/output:/build/build \
        -v /dev/net/tun:/dev/net/tun \
        --cap-add=NET_ADMIN  \
        zbuilder -- -d
}
# build an image - extra debug info
build-debug() {
    docker run --rm -it \
        -v "$(pwd)"/container-boot.d:/container-boot.d \
        -v "$(pwd)"/buildroot:/buildroot \
        -v "$(pwd)"/../:/zfsbootmenu \
        -v "$(pwd)"/output:/build/build \
        -v /dev/net/tun:/dev/net/tun \
        --cap-add=NET_ADMIN  \
        zbuilder -- -dd -d
}
# build an image - shell into builder image - you issue /build-init.sh to build
build-shell() {
    docker run --rm -it \
        -v "$(pwd)"/container-boot.d:/container-boot.d \
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
cmds=(build_builder-debian build_builder-void build build-debug build-shell)
if [ ! -z $cmd ] && [[ " ${cmds[*]} " =~ " $cmd " ]]; then
    $cmd
    exit $?
fi
tmp=${cmds[@]}
echo "Enter a command like ${tmp// /, }"
