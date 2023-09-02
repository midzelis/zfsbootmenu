#### Temporary Fork of ZFSBootMenu to support Tailscale Unlocking and ProxMox chainloading


# !!! This is really rough. Not for any human consumption yet. !!!


## Tailscale Enabled Unlocker for Native ZFS root encryption

* Secure remote unlocking - Never stores keys anywhere! Handles Evil Maid Scenarios
* Uses Tailscale to support NAT'ed locations
* Supports ProxMox - Uses a generic build (Using existing void linux configuration) - which chainloads the proxmox initramfs. 
  * It decrypts the pool containing ProxMox initrd and kernel images, and then injects the manually user-intered key into the ProxMox initrd image (completely in memory) - before loading it. 
  


### Modifications: 

* For /bin/geneate-zdm - add debuging to dracut
* For /zfsbootmenu-core.sh 
  - "hex" format keys can be prompted on the command line, they are text. ("raw" format still aren't, because they are binary)
  - Prompt and record the keys that the user enters (for later injection in the initrd for kexec)

### Considerations
* I use alpine linux to run docker
* I'm not too familiar with Void, dracut, etc
* Leverage the docker build on alpine (Which is running as a QEMU container on my ProxMox bare metal VM host)

### Use case
* Encrypt the root partition for a box hosting ZRepl
* The box is at a "untrusted" area - ZRepl sends raw encrypted backups without the key
* The remote box still needs a root to boot - Dropbear/SSH won't work because its behind a NAT
* So why not tailscale? (Alterantively, bare wireguard could also be used, but tailscale's UI is amazing, and it does NAT traversal elegantly)
* Tailscale also supports transparent ssh, which is also slick - no more
managing authorized keys
* ZFSBootMenu only supports dracut/mkinitcpio - but not Debian's initramfs - thats ok, we can chainload it! 
* clevis/tang was considered, but after thinking long/hard about it - it isn't as secure as tailscale
    * If you have physical access to the machine, you'll be able interrupt the boot process and decrypt the key, since tpm only checks to make sure the boot media wasn't tampered - if you have access to the machine, you'll be able to access the root partition
    * tang would be better - but that requires setting up yet another server. Also, if the box was stolen, and plugged in, and wasn't detected quickly enough, there may be a period of time where the box would contact the server and decrypt root
    * Tailscale - if you don't know yet if the box is stolen or not - you'll have a chance to connect to the box and dig around and determine if its environment looks safe - maybe using network lookups, familiar arps, maybe even considering fingerprinting the pings to various servers accross the world, to determine if it was physically moved. 
        * No protection is truely safe, unless you physically verify it is where its supposed to be. But this comes very close to convenience and security. 
    

### TODO 
 * Load the kernel parameters from /EFI/entries 

### Instructions: (Hint: use QEMU On Proxmox to test)
  * Create/install ProxMox in QEMU using install media, create a ZFS root partition
  * Run `pve_ts-build-builder.sh`` to create `zbuilder` docker image - used to buld the EFI image
  * Run `pve_ts-build-EFI.sh`` - the first time it will ask you to login to Tailscale, and it will save the tailscale state.
    - NOTE - the tailscale node should be unique to the EFI image, and used only for remote unlocking purposes - the node 
    id is not stored encrypted. Use tailscale ACLs to make it so the EFI node can not access your internal network, but you can
    access it. 
  * Copy the EFI image to ProxMox: 
```
    mkdir /efi
    mount /dev/sda2 /efi
    cp vmlinux.EFI /efi/EFI/Linux/vmlinux.EFI
    umount /efi
    reboot
```
  * TODO: Skip using systemd to load ZfsBootMenu - use a direct efi boot
  * Encrypt the ProxMox root partition in place....
  * On some box, generate a secure hex key like
```
    openssl rand -hex 32 
    # which outputs a random string like 1e638c85ef3e6e2ee83df04210b50e61301d3650added95b3de890660094027d
```
  * Enter ZFSBootMenu
  * Use tailscale to connect remotely... 
```
  tailscale ssh zfsbootmenu 
```
  * Enter the recovery shell
    * Enter these commands: 
    * Generate a secure hex key: 
  * Now encrypt the root partition in place
```
  zpool export rpool
  zpool import rpool
  zfs snapshot -r rpool/ROOT@copy
  zfs send -R rpool/ROOT@copy | zfs receive rpool/copyroot
  zfs destroy -r rpool/ROOT
  # (Your key from above)
  echo "1e638c85ef3e6e2ee83df04210b50e61301d3650added95b3de890660094027d" > /root/root_keyfile
  zfs create -o encryption=on -o keyformat=hex -o keylocation=file:///root/root_keyfile rpool/ROOT
  zfs send -R rpool/copyroot/pve-1@copy | zfs receive -o encryption=on rpool/ROOT/pve-1
  zfs destroy -r rpool/copyroot
  zfs set mountpoint=/ rpool/ROOT/pve-1
  zpool export rpool
  ```

### To upgrade the ZFSBootContainer from within the container
* Build a new image
* From the host: `tailscale file cp -h output/vmlinuz.EFI zfsbootmenu:/bin`
* From the ZfsBootMenu recover console 
```
  mkdir /efi
  mount /dev/sda2 /efi
  cp /var/lib/tailscale/files/<someId>/vmlinux.EFI /efi/EFI/Linux/vmlinux.EFI
  umount /efi
```


```
This space intentionally left blank







































```

[![ZFSBootMenu Logo](docs/logos/Logo_TextOnly_Color.svg)](https://zfsbootmenu.org)

[![Build Check](https://github.com/zbm-dev/zfsbootmenu/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/zbm-dev/zfsbootmenu/actions/workflows/build.yml) [![Documentation Status](https://readthedocs.org/projects/zfsbootmenu/badge/?version=latest)](https://docs.zfsbootmenu.org/en/latest/?badge=latest) [![Latest Packaged Version(s)](https://repology.org/badge/latest-versions/zfsbootmenu.svg)](https://repology.org/project/zfsbootmenu/versions)

ZFSBootMenu is a Linux bootloader that attempts to provide an experience similar to FreeBSD's bootloader. By taking advantage of ZFS features, it allows a user to have multiple "boot environments" (with different distributions, for example), manipulate snapshots before booting, and, for the adventurous user, even bootstrap a system installation via `zfs recv`.

In essence, ZFSBootMenu is a small, self-contained Linux system that knows how to find other Linux kernels and initramfs images within ZFS filesystems. When a suitable kernel and initramfs are identified (either through an automatic process or direct user selection), ZFSBootMenu launches that kernel using the `kexec` command.

![screenshot](/media/v2.1.0-multi-be.png)

### For more details, see:

- [Documentation](https://docs.zfsbootmenu.org)
- [Boot Environments and You: A Primer](https://docs.zfsbootmenu.org/en/latest/guides/general/bootenvs-and-you.html)

### Join us on IRC

Come chat about ZFSBootMenu in [#zfsbootmenu on libera.chat](https://web.libera.chat/#zfsbootmenu)
