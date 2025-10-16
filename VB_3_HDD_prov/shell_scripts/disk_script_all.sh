#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------
# 0.  Inform the user that the script is starting
# ------------------------------------------------------------------
echo "=== Starting disk/LVM setup script ==="

# ------------------------------------------------------------------
# 1.  Make sure we have the LVM tools
# ------------------------------------------------------------------
echo "=== 1. Checking for lvm2 ==="
if dpkg -s lvm2 &>/dev/null; then
    echo "lvm2 is installed"
else
    echo "lvm2 is NOT installed"
    echo "Installing lvm2..."
    echo "=== 1a. Updating package lists ==="
    apt-get update
    echo "=== 1b. Installing lvm2 ==="
    apt-get install -y lvm2
fi

# ------------------------------------------------------------------
# 2.  Wait for the kernel to see the new disks
# ------------------------------------------------------------------
echo "=== 2. Waiting for /dev/sdb and /dev/sdc to appear ==="
while [ ! -b /dev/sdb ] || [ ! -b /dev/sdc ]; do
    sleep 1
done
echo "=== 2. Disks are present ==="

# ------------------------------------------------------------------
# 3.  Create a single partition on each disk
# ------------------------------------------------------------------
for dev_name in "sdb" "sdc"; do
    dev="/dev/${dev_name}"
    echo "=== 3. Creating partition on $dev ==="

    # 3a.  Verify we see the disk
    echo "=== 3a. Checking disk properties ==="
    read -r NAME SIZE TYPE MOUNTPOINT < <(
        lsblk -n -o NAME,SIZE,TYPE,MOUNTPOINT "$dev"
    )
    EXPECTED_NAME=$dev_name
    EXPECTED_SIZE="1G"
    if [[ "$NAME" != "$EXPECTED_NAME" || "$SIZE" != "$EXPECTED_SIZE" ]]; then
        echo "ERROR: Device check failed." >&2
        echo "  Expected: name=$EXPECTED_NAME, size=$EXPECTED_SIZE" >&2
        echo "  Found:    name=$NAME, size=$SIZE" >&2
        exit 1
    fi

    # 3b.  Install gdisk if we don't already have it
    echo "=== 3b. Ensuring gdisk is installed ==="
    apt-get update
    apt-get install -y gdisk

    # 3c.  Partition size (300 MiB)
    part_size="300M"

    # 3d.  Create an msdos partition table
    echo "=== 3c. Zapping any existing partition table on $dev ==="
    sgdisk --zap-all "$dev"

    # 3e.  Create two 300 MiB primary partitions
    echo "=== 3d. Creating two 300 MiB partitions on $dev ==="
    sgdisk --new=1:0:+$part_size --typecode=1:8300 "$dev"
    sgdisk --new=2:0:+$part_size --typecode=2:8300 "$dev"

    # 3f.  Re‑read the partition table
    echo "=== 3e. Re‑reading partition table for $dev ==="
    partprobe "$dev" || partx -a "$dev"

    # Wait a bit so the kernel creates /dev/sdb1 /dev/sdb2
    # Option A – udev settle (recommended)
    udevadm settle -t 5
    
    # 3g.  Format the partitions
    echo "=== 3f. Formatting partitions on $dev ==="
    mkfs.ext4 -F "${dev}1"
    mkfs.ext4 -F "${dev}2"
done
echo "=== 3. Partitioning complete ==="

# ------------------------------------------------------------------
# 4.  Create LVM physical volumes
# ------------------------------------------------------------------
echo "=== 4. Creating LVM PVs on all partitions ==="
pvcreate -ff -y /dev/sdb1 /dev/sdb2 /dev/sdc1 /dev/sdc2

# ------------------------------------------------------------------
# 5.  Create a volume group named 'vgdata'
# ------------------------------------------------------------------
echo "=== 5. Creating volume group 'vgdata' ==="
vgcreate vgdata /dev/sdb1 /dev/sdb2 /dev/sdc1 /dev/sdc2

# ------------------------------------------------------------------
# 6.  Create a logical volume – e.g. 1G
# ------------------------------------------------------------------
echo "=== 6. Creating logical volume 'lvdata' (1G) ==="
lvcreate -L 1G -n lvdata vgdata

# ------------------------------------------------------------------
# 7.  Format the LV with ext4
# ------------------------------------------------------------------
echo "=== 7. Formatting /dev/vgdata/lvdata ==="
mkfs.ext4 -F /dev/vgdata/lvdata

# ------------------------------------------------------------------
# 8.  Mount the LV and add to /etc/fstab
# ------------------------------------------------------------------
mount_point="/mnt/lvdata"
echo "=== 8. Mounting /dev/vgdata/lvdata to $mount_point ==="
mkdir -p "$mount_point"
mount /dev/vgdata/lvdata "$mount_point"

echo "=== 8a. Adding mount to /etc/fstab for persistence ==="
echo "/dev/vgdata/lvdata $mount_point ext4 defaults 0 0" >> /etc/fstab

# ------------------------------------------------------------------
# 9.  Done
# ------------------------------------------------------------------
echo "=== All done – disks are partitioned, formatted, and LVM is ready! ==="
