# Ubuntu Upgrade Script - Usage Guide

This guide explains how to download and run the `ubuntu/upgrade.sh` script from the public `andrewsederholm/scripting` GitHub repository.

## What the script does

The script runs in two stages.

### Stage 1 - Prepare the current Ubuntu installation

It will:

1. Update package lists with `apt update`.
2. Install all available updates with `apt full-upgrade -y`.
3. Remove obsolete packages with `apt autoremove --purge -y`.
4. Clean the APT cache with `apt clean`.
5. Create a state file so it knows Stage 1 finished.
6. Wait 10 seconds and reboot the server.

### Stage 2 - Ubuntu release upgrade

After the first reboot, run the same script again. It sees the Stage 1 state file and proceeds to Stage 2.

It will:

1. Set the upgrade environment to noninteractive.
2. Run `do-release-upgrade -f DistUpgradeViewNonInteractive`.
3. Remove the Stage 1 state file after the release upgrade completes.
4. Wait 10 seconds and reboot the server again.

## Before you run it

Because this script installs system updates, performs an Ubuntu release upgrade, and reboots the machine, use it only on a system you are prepared to upgrade.

For a remote server, make sure you have console or other recovery access available in case networking or the operating system does not return normally after an upgrade.

## Download only the upgrade script

You do **not** need to clone the entire GitHub repository.

From the Ubuntu server, run:

```bash
cd ~
wget https://raw.githubusercontent.com/andrewsederholm/scripting/main/ubuntu/upgrade.sh
```

Verify that the file exists:

```bash
ls -l upgrade.sh
```

## Make the script executable

Run:

```bash
chmod +x upgrade.sh
```

Verify the permissions:

```bash
ls -l upgrade.sh
```

You should see executable permissions similar to:

```text
-rwxr-xr-x ... upgrade.sh
```

## Run Stage 1

If you are logged in as `root`:

```bash
./upgrade.sh
```

If you are logged in as a normal sudo-enabled user:

```bash
sudo ./upgrade.sh
```

The script will update and clean the current Ubuntu installation and then reboot the machine.

**Your SSH connection will disconnect when the server reboots. This is expected.**

## After the first reboot

SSH back into the server.

If the script was downloaded to root's home directory:

```bash
cd /root
```

Otherwise, return to the directory where `upgrade.sh` was downloaded.

Then run the **same script again**:

```bash
./upgrade.sh
```

Or, for a normal sudo-enabled user:

```bash
sudo ./upgrade.sh
```

Because Stage 1 was already completed, the script will proceed to the Ubuntu release-upgrade stage.

When the release upgrade completes, the script will reboot the server again.

## After the second reboot

Reconnect to the server and verify the installed Ubuntu release:

```bash
lsb_release -a
```

You can also check the kernel with:

```bash
uname -r
```

## Download the newest copy later

If `upgrade.sh` already exists and you want to replace it with the latest copy from the repository, run:

```bash
wget -O upgrade.sh https://raw.githubusercontent.com/andrewsederholm/scripting/main/ubuntu/upgrade.sh
chmod +x upgrade.sh
```

Then run it normally:

```bash
./upgrade.sh
```

## Quick reference

### First run

```bash
cd ~
wget https://raw.githubusercontent.com/andrewsederholm/scripting/main/ubuntu/upgrade.sh
chmod +x upgrade.sh
./upgrade.sh
```

The server reboots.

### Second run

Reconnect over SSH, then:

```bash
cd ~
./upgrade.sh
```

The release upgrade runs and the server reboots again.

## Important

Do not interrupt the server while package installation or the Ubuntu release upgrade is actively making system changes. If unexpected errors appear, stop and investigate the error before attempting another upgrade.
