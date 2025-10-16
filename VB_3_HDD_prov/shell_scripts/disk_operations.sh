#!/usr/bin/env bash

# chmod +x disk_operations.sh
# ./disk_operations.sh

set -euo pipefail
DISK=/dev/sdb

# 1. Make sure we see the disk

# Grab the values
read -r NAME SIZE TYPE MOUNTPOINT < <(
    lsblk -n -o NAME,SIZE,TYPE,MOUNTPOINT "$DEVICE"
)

# Expected values
EXPECTED_NAME="sdc"
EXPECTED_SIZE="1G"

# Validate
if [[ "$NAME" != "$EXPECTED_NAME" || "$SIZE" != "$EXPECTED_SIZE" ]]; then
    echo "ERROR: Device check failed." >&2
    echo "  Expected: name=$EXPECTED_NAME, size=$EXPECTED_SIZE" >&2
    echo "  Found:    name=$NAME, size=$SIZE" >&2
    exit 1          # stops the script immediately
fi

# 2. Create an msdos partition table
sudo sgdisk --zap-all $DISK
# sudo sgdisk --mbrtogpt $DISK   # optional if you prefer GPT; remove if you want msdos
# OR: sudo parted -s $DISK mklabel msdos

# 3. Create two 300 MiB primary partitions
sudo sgdisk --new=1:0:+300M --typecode=1:0700 $DISK
sudo sgdisk --new=2:0:+300M --typecode=2:0700 $DISK

# 4. (Optional) Mark them as bootable
sudo sgdisk --attributes=1:set:2 $DISK
sudo sgdisk --attributes=2:set:2 $DISK

# 5. Re‑read the partition table
sudo partprobe $DISK || sudo partx -a $DISK

# 6. Format the partitions
sudo mkfs.ext4 -F ${DISK}1
sudo mkfs.ext4 -F ${DISK}2

# 7. Mount them
sudo mkdir -p /mnt/part1 /mnt/part2
sudo mount ${DISK}1 /mnt/part1
sudo mount ${DISK}2 /mnt/part2

# 8. Persist mounts
sudo bash -c "cat >>/etc/fstab <<EOF
${DISK}1 /mnt/part1 ext4 defaults 0 2
${DISK}2 /mnt/part2 ext4 defaults 0 2
EOF"