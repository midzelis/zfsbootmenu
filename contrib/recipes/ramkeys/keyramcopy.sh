#!/bin/bash

set -x

bash
if [ -d /run/zbm_keys ] && [[ "$(ls /run/zbm_keys)" ]]; then
    find /run/zbm_keys -depth -print | pax -s "/\/run\/zbm_keys//" -x sv4cpio -wd | zstd >> "$1"
fi
bash