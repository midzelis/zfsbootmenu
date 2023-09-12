#!/bin/bash


out="$ZBMOUTPUT/boot-vfs.raw"
echo "Generating raw file image for VM to $out"
rm -f out
dd if=/dev/zero of="$out" bs=1M count=256
mformat -i "$out" ::
mmd -i "$out" ::/EFI
mmd -i "$out" ::/EFI/BOOT
mcopy -i "$out" "$ZBMOUTPUT/vmlinuz.EFI" ::/EFI/BOOT/BOOTX64.EFI
