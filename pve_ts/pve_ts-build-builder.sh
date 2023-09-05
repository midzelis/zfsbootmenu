#!/bin/bash

# This creates an image called 'zbuilder', to be used in the pve_ts-build-EFI.sh script
docker build -f Dockerfile.void -t zbuilder .