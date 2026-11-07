#!/bin/bash

set -e

# ============================================================
# Ubuntu Server Configuration Script
#
# - Sets timezone to America/Denver
# - Disables Ubuntu MOTD news
# - Removes Ubuntu documentation/management/support links
# - Hides Ubuntu Pro / ESM promotional notices
# ============================================================

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root."
    echo
    echo "Run:"
    echo "sudo ./configure.sh"
    exit 1
fi

echo
echo "=========================================="
echo "    Ubuntu Server Configuration"
echo "=========================================="
echo


# ============================================================
# TIMEZONE
# ============================================================

echo "=== Setting timezone to America/Denver ==="

timedatectl set-timezone America/Denver

echo
echo "Current time:"
timedatectl | grep -E "Local time|Time zone"


# ============================================================
# DISABLE MOTD NEWS
# ============================================================

echo
echo "=== Disabling Ubuntu MOTD news ==="

if [[ -f /etc/default/motd-news ]]; then
    sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
fi


# ============================================================
# REMOVE DOCUMENTATION / MANAGEMENT / SUPPORT LINKS
# ============================================================

echo
echo "=== Removing Ubuntu help/support links from login ==="

if [[ -f /etc/update-motd.d/10-help-text ]]; then
    chmod -x /etc/update-motd.d/10-help-text
fi


# ============================================================
# HIDE UBUNTU PRO / ESM MOTD MESSAGES
# ============================================================

echo
echo "=== Hiding Ubuntu Pro / ESM login messages ==="

mkdir -p /var/lib/update-notifier
touch /var/lib/update-notifier/hide-esm-in-motd

if [[ -x /usr/lib/update-notifier/update-motd-updates-available ]]; then
    /usr/lib/update-notifier/update-motd-updates-available --force || true
fi


# ============================================================
# DISABLE UBUNTU PRO APT NEWS
# ============================================================

echo
echo "=== Disabling Ubuntu Pro APT news ==="

if command -v pro >/dev/null 2>&1; then
    pro config set apt_news=false || true
fi


# ============================================================
# COMPLETE
# ============================================================

echo
echo "=========================================="
echo "       CONFIGURATION COMPLETE"
echo "=========================================="
echo
echo "Timezone:"
timedatectl | grep "Time zone"

echo
echo "Ubuntu MOTD news: Disabled"
echo "Ubuntu help/support links: Disabled"
echo "Ubuntu Pro / ESM MOTD notices: Hidden"
echo "Ubuntu Pro APT news: Disabled"
echo
echo "Log out and reconnect over SSH to see the cleaned-up login."
echo
# ============================================================
# COMPLETE / REBOOT
# ============================================================

echo
echo "=========================================="
echo "       CONFIGURATION COMPLETE"
echo "=========================================="
echo
echo "Timezone:"
timedatectl | grep "Time zone"

echo
echo "Ubuntu MOTD news: Disabled"
echo "Ubuntu help/support links: Disabled"
echo "Ubuntu Pro / ESM MOTD notices: Hidden"
echo "Ubuntu Pro APT news: Disabled"
echo

echo "System will reboot in..."

for i in {5..1}; do
    echo "$i..."
    sleep 1
done

echo
echo "Rebooting now!"

reboot
