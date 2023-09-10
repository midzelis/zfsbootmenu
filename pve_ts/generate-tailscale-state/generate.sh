#!/bin/bash
docker build -t gen-ts .
docker run -it --rm \
    -v "$(pwd)":/out \
    -v /dev/net/tun:/dev/net/tun \
    --cap-add=NET_ADMIN  \
    gen-ts

