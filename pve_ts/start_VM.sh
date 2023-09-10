#!/bin/bash

#apk add qemu-system-x86_64

qemu-system-x86_64 \
-m 8G \
-smp 6 \
-usb \
-device usb-tablet \
-device usb-kbd \
-display default,show-cursor=on \
-machine q35,vmport=off,i8042=off,hpet=off \
-device virtio-scsi-pci,id=scsi0 \
-drive file=../../pm.qcow2,if=none,discard=unmap,id=drive1 \
-device scsi-hd,drive=drive1,bus=scsi0.0,bootindex=1 \
-drive if=none,format=raw,file=/LUNA/ALPHA/PVE_VIRTUAL_MACHINES/NFS_DISKS/images/2200/vm-2200-disk-0.raw,id=drive2 \
-kernel output/vmlinuz-bootmenu \
-initrd output/initramfs-bootmenu.img \
-display curses \
-device VGA,vgamem_mb=64 \
-append 'vga=0x0942'
#-device vmware-svga,ram_size=268435456,vgamem_mb=256,vram_size=268435456 

# -append 'console=ttyS0' \
# -nographic \

#backup
# qemu-system-x86_64 \
# -m 8G \
# -smp 6 \
# -usb \
# -device usb-tablet \
# -device usb-kbd \
# -display default,show-cursor=on \
# -drive if=pflash,format=raw,file=/usr/share/OVMF/OVMF_CODE.fd,readonly=on \
# -machine q35,vmport=off,i8042=off,hpet=off \
# -device virtio-scsi-pci,id=scsi0 \
# -drive file=../../pm.qcow2,if=none,discard=unmap,id=drive1 \
# -device scsi-hd,drive=drive1,bus=scsi0.0,bootindex=1 \
# -drive if=none,format=raw,file=/LUNA/ALPHA/PVE_VIRTUAL_MACHINES/NFS_DISKS/images/2200/vm-2200-disk-0.raw,id=drive2 \
# -device scsi-hd,drive=drive2,bus=scsi0.0,bootindex=0 \
# -nographic \
# -serial mon:stdio