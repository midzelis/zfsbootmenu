#!/bin/bash

# dd if=/dev/zero of="$BUILDROOT/boot-vfs" bs=1024 count=256000
# losetup /dev/loop0
# sudo losetup /dev/loop0 "$BUILDROOT/boot-vfs"
# mkfs.vfat /dev/loop0
# mount /dev/loop0 /vfs
# mkdir -p /vfs/BOOT
# cp $BUILDROOT/vmlinuz.EFI /vfs/BOOT/BOOTX64.EFI
# umount /vfs

# brew tap uenob/qemu-hvf
# brew install --head qemu-hvf
# brew install ovmf


out="$ZBMOUTPUT/boot-vfs.raw"
rm -f out
dd if=/dev/zero of="$out" bs=1M count=256
mformat -i "$out" ::
mmd -i "$out" ::/EFI
mmd -i "$out" ::/EFI/BOOT
mcopy -i "$out" "$ZBMOUTPUT/vmlinuz.EFI" ::/EFI/BOOT/BOOTX64.EFI