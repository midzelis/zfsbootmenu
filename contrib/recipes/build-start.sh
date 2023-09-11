

#!/bin/bash

# racut copies all files using cp --preserve which fails if the host uses NFS to mount this folder
# The easiest way for me to fix that is to bind mount the inputs to the build
# and then copy them to a folder within the container. 

mkdir -p /zbm
cp -R /zfsbootmenu/* /zbm

mkdir -p /var/lib/tailscale
# todo - add a hook for this
cp /zbm/contrib/recipes/net-tailscale/tailscaled.state /var/lib/tailscale/tailscaled.state

# find "$BUILDROOT"/modules.d/* -maxdepth 1 -type d -exec ln -sv {} /usr/lib/dracut/modules.d/ \;

cp -v /zbm/etc/zfsbootmenu/release.conf.d/* /zbm/etc/zfsbootmenu/dracut.conf.d

mkdir -p "$BUILDROOT"

echo merging config
yq-go eval-all '. as $item ireduce ({}; . *+ $item) | (... | select(type == "!!seq")) |= unique' /zbm/contrib/recipes/base-config.yaml /zbm/contrib/recipes/*/config.yaml > "$BUILDROOT"/config.yaml
echo merged config:
yq-go "$BUILDROOT"/config.yaml
echo $BUILDROOT
