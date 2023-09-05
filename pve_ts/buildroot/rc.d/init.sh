#!/bin/bash

mkdir -p /etc/cmdline.d
echo "ip=dhcp rd.neednet=1" > /etc/cmdline.d/dracut-network.conf
find /build/modules.d/* -maxdepth 1 -type d -exec ln -sv {} /usr/lib/dracut/modules.d/ \;
( cd /zfsbootmenu ; git rev-parse HEAD > /etc/zbm-commit-hash )

if [ ! -f /build/build/tailscaled.state ]; then
    echo "Could not find tailscale state, creating" 
    tailscaled --state=/build/build/tailscaled.state &
    tailscale login
    tailscale up --ssh
fi
