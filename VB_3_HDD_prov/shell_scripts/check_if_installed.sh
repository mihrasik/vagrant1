#!/usr/bin/env bash

# chmod +x check_if_installed.sh
# ./check_if_installed.sh

set -euo pipefail

if dpkg -s lvm2 &>/dev/null; then
    echo "lvm2 is installed"
else
    echo "lvm2 is NOT installed"
fi