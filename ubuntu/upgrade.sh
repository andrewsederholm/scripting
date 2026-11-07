#!/bin/bash

set -e

# ============================================================
# Ubuntu Upgrade Script
#
# Stage 1:
#   - Update package lists
#   - Install all available updates
#   - Remove obsolete packages
#   - Clean apt cache
#   - Reboot
#
# Stage 2:
#   - Run Ubuntu release upgrade
#   - Reboot
#
# After the first reboot, run this same script again.
# ============================================================

# Make sure the script is being run as root
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root."
    echo
    echo "Run:"
    echo "sudo ./upgrade.sh"
    exit 1
fi

# File used to remember that Stage 1 has already completed
STATE_FILE="/var/lib/ubuntu-upgrade-stage1-complete"

echo
echo "=========================================="
echo "        Ubuntu Upgrade Script"
echo "=========================================="
echo


# ============================================================
# STAGE 1
# ============================================================

if [[ ! -f "$STATE_FILE" ]]; then

    echo "=== STAGE 1: Preparing system for upgrade ==="
    echo

    echo "=== Updating package lists ==="
    apt update

    echo
    echo "=== Installing all available updates ==="
    apt full-upgrade -y

    echo
    echo "=== Removing obsolete packages ==="
    apt autoremove --purge -y

    echo
    echo "=== Cleaning apt cache ==="
    apt clean

    echo
    echo "=== Marking Stage 1 as complete ==="
    touch "$STATE_FILE"

    echo
    echo "=========================================="
    echo "        STAGE 1 COMPLETE"
    echo "=========================================="
    echo
    echo "The system will reboot in 10 seconds."
    echo
    echo "After the reboot:"
    echo
    echo "1. SSH back into the server"
    echo "2. Go back to the scripting/ubuntu directory"
    echo "3. Run:"
    echo
    echo "   sudo ./upgrade.sh"
    echo
    echo "The script will automatically continue with Stage 2."
    echo

    sleep 10
    reboot

    exit 0
fi


# ============================================================
# STAGE 2
# ============================================================

echo "=== Stage 1 has already been completed ==="
echo
echo "=== STAGE 2: Starting Ubuntu release upgrade ==="
echo

export DEBIAN_FRONTEND=noninteractive

do-release-upgrade -f DistUpgradeViewNonInteractive

echo
echo "=== Release upgrade completed ==="

# Remove the state file so the script can be used again later
rm -f "$STATE_FILE"

echo
echo "=========================================="
echo "        UPGRADE COMPLETE"
echo "=========================================="
echo
echo "The system will reboot in 10 seconds."
echo

sleep 10
reboot
