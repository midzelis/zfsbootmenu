#!/bin/bash

# I launch my docker containers on a host that uses NFS to mount this
# git repo, and dracut copies all files using cp --preserve which fails
# The easiest way for me to fix that is to bind mount the inputs to the build
# and then copy them to a folder within the container. 

mkdir -p "$BUILDROOT"
cp -R /buildroot/* "$BUILDROOT"

mkdir -p /zbm
cp -R /zfsbootmenu/* /zbm

mkdir -p /var/lib/tailscale
cp /buildroot/tailscaled.state /var/lib/tailscale/tailscaled.state
# find "$BUILDROOT"/modules.d/* -maxdepth 1 -type d -exec ln -sv {} /usr/lib/dracut/modules.d/ \;