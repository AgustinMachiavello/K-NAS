#!/bin/bash

# K-NAS version
KNAS_VERSION="0.1"

# K-NAS title
KNAS_TITLE="K-NAS v$KNAS_VERSION"

# Where the main data disk is mounted. Other disks you add are mounted next to it, under /mnt
STORAGE_DIR="${STORAGE_DIR:-/mnt/storage}"
DISKS_DIR="/mnt"

# Folders created under STORAGE_DIR on the main disk (used for the confirmation text and for mkdir)
STORAGE_FOLDERS="media/movies media/series media/music media/photos media/audiobooks media/ebooks media/games documents repos shared software downloads docker"

# Where K-NAS keeps its state: setup status and the list of installed apps
KNAS_STATE_DIR="${KNAS_STATE_DIR:-/var/lib/k-nas}"
SETUP_DONE="$KNAS_STATE_DIR/setup-done"
APPS_FILE="${APPS_FILE:-$KNAS_STATE_DIR/apps}"

# Where K-NAS is installed.
KNAS_INSTALL_DIR="/opt/k-nas"

# Where the apps live: one folder per app, with app.conf and docker-compose.yml
KNAS_SERVICES_DIR="${KNAS_SERVICES_DIR:-$KNAS_DIR/../services}"

# Scheduled backups settings
BACKUP_CONF="${BACKUP_CONF:-/etc/k-nas-backup.conf}"
BACKUP_CRON="${BACKUP_CRON:-/etc/cron.d/k-nas-backup}"
BACKUP_LOG="${BACKUP_LOG:-/var/log/k-nas-backup.log}"
BACKUP_LAST="${BACKUP_LAST:-$KNAS_STATE_DIR/last-backup}"
BACKUP_DIRNAME="k-nas-backup"

# Import data from another disk: the filesystems we can read, where the old disk is mounted
# (read-only), and the log, result and lock of a copy that is running in the background
IMPORT_FILESYSTEMS="ext2 ext3 ext4 btrfs xfs"
IMPORT_MOUNT="/mnt/k-nas-import"
IMPORT_LOG="/var/log/k-nas-import.log"
IMPORT_RESULT="/run/k-nas-import.result"
IMPORT_LOCK="/run/k-nas-import.lock"

# Custom settings
#

KNAS_CONF="${KNAS_CONF:-/etc/k-nas.conf}"
if [ -f "$KNAS_CONF" ]; then
    # shellcheck source=/dev/null
    source "$KNAS_CONF"
fi
