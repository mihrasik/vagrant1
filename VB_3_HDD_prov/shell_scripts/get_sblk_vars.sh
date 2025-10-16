#!/usr/bin/env bash

# chmod +x get_sblk_vars.sh
# ./get_sblk_vars.sh

set -euo pipefail

DEVICE="/dev/sdb"

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

# Use the variables
echo "Device: $DEVICE"
echo "Name:      $NAME"
echo "Size:      $SIZE"
echo "Type:      $TYPE"
echo "Mountpoint:$MOUNTPOINT"
