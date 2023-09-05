#!/bin/bash


# interactive mode (debugging)
docker run --rm -it \
    -v "$(pwd)"/buildroot:/buildroot \
    -v "$(pwd)"/../:/zfsbootmenu \
    -v "$(pwd)"/output:/build/build \
    -v /dev/net/tun:/dev/net/tun \
    --cap-add=NET_ADMIN  \
    --entrypoint=/bin/bash \
    zbuilder 