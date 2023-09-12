#!/bin/bash
# this will be remove before PR

#apk add qemu-system-x86_64

APPEND=("console=ttyS0")
LINES="$( tput lines 2>/dev/null )"
COLUMNS="$( tput cols 2>/dev/null )"
[ -n "${LINES}" ] && APPEND+=( "zbm.lines=${LINES}" )
[ -n "${COLUMNS}" ] && APPEND+=( "zbm.columns=${COLUMNS}" )

echo "${APPEND[*]}"
qemu-system-x86_64 \
-m 2G \
-smp cores=2,threads=16 \
-display default,show-cursor=on \
-machine q35,vmport=off,i8042=off,hpet=off \
-device virtio-scsi-pci,id=scsi0 \
-drive file=../../pm.qcow2,if=none,discard=unmap,id=drive1 \
-device scsi-hd,drive=drive1,bus=scsi0.0,bootindex=1 \
-drive if=none,format=raw,file=/LUNA/ALPHA/PVE_VIRTUAL_MACHINES/NFS_DISKS/images/2200/vm-2200-disk-0.raw,id=drive2 \
-net nic,model=virtio \
-net user \
-kernel output/vmlinuz-bootmenu \
-initrd output/initramfs-bootmenu.img \
-nographic \
-serial "mon:stdio" \
-append "${APPEND[*]}"

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