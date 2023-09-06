#!/bin/bash
set -x
mkdir -p /etc/cmdline.d
echo "ip=dhcp rd.neednet=1" > /etc/cmdline.d/dracut-network.conf
#find /build/modules.d/* -maxdepth 1 -type d -exec ln -sv {} /usr/lib/dracut/modules.d/ \;

