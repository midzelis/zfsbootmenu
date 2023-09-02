#!/bin/bash

mkdir -p /etc/cmdline.d
echo "ip=dhcp rd.neednet=1" > /etc/cmdline.d/dracut-network.conf

ln -sf /build/modules.d/40tailscale /usr/lib/dracut/modules.d

if [ ! -f /build/build/tailscaled.state ]; then
    echo "Could not find tailscale state, creating" 
    tailscaled --state=/build/build/tailscaled.state &
    tailscale login
    tailscale up --ssh
fi
