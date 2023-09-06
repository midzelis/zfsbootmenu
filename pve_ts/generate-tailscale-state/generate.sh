#!/bin/bash
docker build -t gen-ts .
docker run -it --rm -v /tailscaled.state:/tailscaled.state /gen-ts