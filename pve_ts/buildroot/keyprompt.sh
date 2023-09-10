#!/bin/bash

fs=$1
encroot=$2
key=$3
keyformat=$4

gum style --bold --border double --align center --width 50 --margin "1 2" --padding "2 4" "Found encrypted filesystem \'$fs\' (encryptionroot=$encroot)" "Skip in 10 seconds"

# shellcheck disable=SC2034
for i in $(seq 1 3); do
    keyinput=$(gum input --placeholder="Type your key" --header="Enter $keyformat key for $encroot" --password --timeout=10s)
    # read -r -t 10 -s -p "Enter $keyformat key for $encroot:  " keyinput
    if [ -z "$keyinput" ]; then
        printf "\n\n"
        exit 1
    fi
    echo "$keyinput" | zfs load-key -L prompt "${encroot}"
    ret=$?
    printf "\n\n"
    if (( ret == 0 )); then
        keydir=$(dirname "$key")
        keyfile=$(basename "$key")
        mkdir -p "/run/zbm_keys/$keydir"
        echo "$keyinput" > "/run/zbm_keys/$keydir/$keyfile"
        exit 0
    fi
done
exit 1