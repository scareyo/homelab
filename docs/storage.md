# Storage

## ZFS Pool

```
chroot /host zpool create -f \
    -o ashift=12 \
    -O mountpoint=/var/mnt/s-flamingo \
    -O compression=zstd \
    -O xattr=sa \
    -O acltype=posixacl \
    -O atime=off \
    s-flamingo raidz2 \
    /dev/disk/by-id/ata-ST28000NM000C-3WM103_ZXA07LM3 \
    /dev/disk/by-id/ata-ST28000NM000C-3WM103_ZXA09SWH \
    /dev/disk/by-id/ata-ST28000NM000C-3WM103_ZXA07Y91 \
    /dev/disk/by-id/ata-ST28000NM000C-3WM103_ZXA07CNP \
    /dev/disk/by-id/ata-ST28000NM000C-3WM103_ZXA0GVFL
```
