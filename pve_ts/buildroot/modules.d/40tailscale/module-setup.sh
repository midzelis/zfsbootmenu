#!/bin/bash

# called by dracut
check() {
    require_binaries tailscale tailscaled || exit 1
    return 0
}

# called by dracut
depends() {
    echo "network"
    return 0
}

# called by dracut
install() {
    inst_binary tailscale || exit 1
    inst_binary tailscaled || exit 1
    inst_binary iptables || exit 1
    inst_binary ip6tables || exit 1

    inst_binary vi || exit 1
    inst_binary curl || exit 1
    
    cp /build/build/tailscaled.state /tmp
    inst_simple "tmp/tailscaled.state" /var/lib/tailscale/tailscaled.state || exit 1
    inst_hook initqueue/online 88 "$moddir/start-tailscale.sh" || exit 1
    inst_script "$moddir/start-tailscale.sh" /sbin/start-tailscale.sh || exit 1
    return 0
}

# called by dracut
installkernel() {
    instmods '=net/netfilter' || exit 1
    return 0
}