#!/bin/bash
mkdir -p /var/log/tailscale
tailscaled --statedir=/var/lib/tailscale &> /var/log/tailscale/tailscale.log &
