#!/bin/bash
tailscaled --statedir=/var/lib/tailscale > /dev/kmsg 2>&1 &
