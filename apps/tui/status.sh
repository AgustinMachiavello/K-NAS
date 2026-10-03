#!/bin/bash

# Checks what is already set up on this machine.

# Paths
KNAS_DIR="${KNAS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
source "$KNAS_DIR/config.sh"


# ---------- Storage ----------

# The main data folder, if a disk is mounted there. Prints nothing otherwise.
storage_root() {
    if mountpoint -q "$STORAGE_DIR" 2>/dev/null; then
        echo "$STORAGE_DIR"
    fi
}

# Step 1: the main data disk is mounted
storage_configured() {
    [ -n "$(storage_root)" ]
}

# Mount points used by a disk or its partitions, one per line (nothing if unused)
disk_mountpoints() {
    lsblk -nro MOUNTPOINTS "$1" | grep . || true
}

# Succeeds if nothing on the disk is mounted
disk_is_free() {
    [ -z "$(disk_mountpoints "$1")" ]
}

# Short description of what is on a disk
disk_summary() {
    local disk="$1" mounts line filesystems="" fstype label

    mounts=$(disk_mountpoints "$disk" | paste -sd, - | sed 's/,/, /g')

    if [ -n "$mounts" ]; then
        # Root, boot or swap on this disk means it is the system disk
        if grep -Eq '(^|, )(/|/boot[^,]*|\[SWAP\])(,|$)' <<< "$mounts"; then
            echo "SYSTEM disk (in use: $mounts)"
        else
            echo "IN USE ($mounts)"
        fi
        return
    fi

    # Filesystems found on the disk and its partitions
    while read -r line; do
        [[ $line =~ FSTYPE=\"([^\"]*)\"\ LABEL=\"([^\"]*)\" ]] || continue
        fstype="${BASH_REMATCH[1]}"
        label="${BASH_REMATCH[2]//\\x20/ }"
        [ -n "$fstype" ] || continue
        # shellcheck disable=SC2016  # the quotes around the label are literal
        filesystems+="${filesystems:+, }$fstype${label:+ '$label'}"
    done < <(lsblk -nPo FSTYPE,LABEL "$disk")

    if [ -n "$filesystems" ]; then
        echo "HAS DATA: $filesystems"
    else
        echo "empty"
    fi
}

# Mounted data disks under DISKS_DIR other than the main one
extra_disks() {
    local dir
    for dir in "$DISKS_DIR"/*/; do
        dir="${dir%/}"
        [ "$dir" = "$STORAGE_DIR" ] && continue
        [ "$dir" = "$IMPORT_MOUNT" ] && continue
        if mountpoint -q "$dir" 2>/dev/null; then
            echo "$dir"
        fi
    done
}


# ---------- Docker ----------

# Step 2: Docker is installed
docker_configured() {
    command -v docker >/dev/null 2>&1
}

# Menu mark for a step: "[x]" if done, "[ ]" if not
mark() {
    if "$1"; then echo "[x]"; else echo "[ ]"; fi
}


# ---------- Apps ----------

# Step 3: at least one app is installed
apps_configured() {
    [ -s "$APPS_FILE" ]
}

# Succeeds if the app with the ID is installed
app_installed() {
    grep -qx "$1" "$APPS_FILE" 2>/dev/null
}

# Print one field of an app's app.conf.
app_field() {
    # shellcheck source=/dev/null
    ( source "$KNAS_SERVICES_DIR/$1/app.conf" && echo "${!2}" )
}

# App web port
app_port() {
    local override
    override="APP_PORT_$(tr 'a-z-' 'A-Z_' <<< "$1")"
    echo "${!override:-$(app_field "$1" APP_PORT)}"
}


# ---------- Backups ----------

# A backup is set up when its settings file exists
backup_configured() {
    [ -f "$BACKUP_CONF" ]
}

# The backup runs (folders named like 2026-10-03_030000) inside a backup folder, oldest first.
# Usage: backup_runs /mnt/disk2/k-nas-backup
backup_runs() {
    local dir
    for dir in "$1"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]; do
        if [ -d "$dir" ]; then
            basename "$dir"
        fi
    done
}

# One line about the last backup run, like "OK 2026-10-03 03:00", or nothing if it never ran
backup_last() {
    cat "$BACKUP_LAST" 2>/dev/null || true
}


# ---------- Network address ----------

# The main IP address of this machine (empty if it has none)
primary_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}


# ---------- Reset ----------

# Forget the setup progress: the "finished" mark and the list of installed apps.
# Does not remove any software, app or data.
forget_setup_state() {
    rm -f "$SETUP_DONE" "$APPS_FILE"
}
