#!/bin/bash

# Checks the whole NAS and prints one line per check: [x] fine, [ ] needs attention.
# Needs no whiptail. Run it as root, since some checks (Docker) need it.

source "$(dirname "${BASH_SOURCE[0]}")/status.sh"

# Print a check.
check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "[x] $label"
    else
        echo "[ ] $label"
    fi
}

backup_ok() { backup_configured && [[ "$(backup_last)" == OK* ]]; }
backup_recent() { [ -z "$(find "$BACKUP_LAST" -mtime +8 2>/dev/null)" ]; }
docker_running() { systemctl is-active --quiet docker; }
disk_not_full() { [ "$(df --output=pcent "$(storage_root)" | tail -n 1 | tr -dc '0-9')" -lt 90 ]; }
app_running() { [ -n "$(docker compose -p "k-nas-$1" ps --status running -q 2>/dev/null)" ]; }

check "A data disk is mounted ($(storage_root))" storage_configured
if storage_configured; then
    check "The data disk is less than 90% full" disk_not_full
fi
check "Docker is installed" docker_configured
check "Docker is running" docker_running
check "A backup is set up and the last run worked ($(backup_last | grep . || echo never))" backup_ok
if backup_configured; then
    check "The last backup is less than 8 days old" backup_recent
fi

if [ -s "$APPS_FILE" ]; then
    while read -r id; do
        check "App $(app_field "$id" APP_NAME) is running" app_running "$id"
    done < "$APPS_FILE"
fi
