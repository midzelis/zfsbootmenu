  #!/bin/bash
  # ignore - not ready yet
  exit 1

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

