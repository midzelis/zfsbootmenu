#!/bin/bash
set -x
if [ ! -f /out/tailscaled.state ]; then 
    echo 'Could not find tailscale state, creating' 
    tailscaled --state=/out/tailscaled.state & 
    tailscale login 
    tailscale up --ssh 
else    
    echo 'Not creating tailscale state - already exits'
fi