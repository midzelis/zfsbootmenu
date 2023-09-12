This is supposed to be a way to easily combine fragments "recipes" into an image


# Very out of date - ignore this!

# Tailscale Enabled Unlocker for Native ZFS root encryption

* Secure remote unlocking - Never stores keys anywhere! Handles Evil Maid Scenarios
* Uses Tailscale to support NAT'ed locations
* Supports ProxMox - Uses a generic build (Using existing void linux configuration) - which chainloads the proxmox initramfs. 
  * It decrypts the pool containing ProxMox initrd and kernel images, and then injects the manually user-intered key into the ProxMox initrd image (completely in memory) - before loading it. 
  

This is really rough. Not for any human consumption yet. 


Modifications: 

For /bin/geneate-zdm - add debuging to dracut
For /zfsbootmenu-core.sh 
  - "hex" format keys can be prompted on the command line, they are text. ("raw" format still aren't, because they are binary)
  - Prompt and record the keys that the user enters (for later injection in the initrd for kexec)


Instructions: (Use QEMU (On Proxmox!) to test)
  Create/install ProxMox in QEMU using install media, create a ZFS root partition
  Run pve_ts-build-builder.sh to create `zbuilder` docker image - used to buld the EFI image
  Run pve_ts-build-EFI.sh - the first time it will ask you to login to Tailscale, and it will save the tailscale state.
    - NOTE - the tailscale node should be unique to the EFI image, and used only for remote unlocking purposes - the node 
    id is not stored encrypted. Use tailscale ACLs to make it so the EFI node can not access your internal network, but you can
    access it. 
  Copy the EFI image to ProxMox: 
    ```
    mkdir /efi
    mount /dev/sda2 /efi
    cp vmlinux.EFI /efi/EFI/Linux/vmlinux.EFI
    umount /efi
    reboot
    ```
  TODO: Skip using systemd to load ZfsBootMenu - use a direct efi boot
  Encrypt the ProxMox root partition in place....
  Enter ZFSBootMenu
  Use tailscale to connect remotely... 
  ```
  tailscale ssh zfsbootmenu 
  ```
  enter the recovery shell
  Enter these commands: 
  Generate a secure hex key: 
  ```
  openssl rand -hex 32 
  ```
  which outputs a random string like 1e638c85ef3e6e2ee83df04210b50e61301d3650added95b3de890660094027d
  Now encrypt the root partition in place
  ```
  zpool export rpool
  zpool import rpool
  zfs snapshot -r rpool/ROOT@copy
  zfs send -R rpool/ROOT@copy | zfs receive rpool/copyroot
  zfs destroy -r rpool/ROOT
  echo "1e638c85ef3e6e2ee83df04210b50e61301d3650added95b3de890660094027d" > /root/root_keyfile
  zfs create -o encryption=on -o keyformat=hex -o keylocation=file:///root/root_keyfile rpool/ROOT
  zfs send -R rpool/copyroot/pve-1@copy | zfs receive -o encryption=on rpool/ROOT/pve-1
  zfs destroy -r rpool/copyroot
  zfs set mountpoint=/ rpool/ROOT/pve-1
  zpool export rpool
  ```

To upgrade the ZFSBootContainer from within the container
Build a new image
From the host: `tailscale file cp -h output/vmlinuz.EFI zfsbootmenu:/bin`
From the ZfsBootMenu recover console 
```
  mkdir /efi
  mount /dev/sda2 /efi
  cp /var/lib/tailscale/files/<someId>/vmlinux.EFI /efi/EFI/Linux/vmlinux.EFI
  umount /efi
  ```
