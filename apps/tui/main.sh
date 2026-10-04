#!/bin/bash

# K-NAS welcome screen, shown at login. Needs no root.

KNAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Print health checks
source "$KNAS_DIR/status.sh"


# Network addresses
addresses=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $2 "  " $4}')

# Storage status
root=$(storage_root)
if [ -n "$root" ]; then
    storage=$(df -h --output=avail,size "$root" | tail -n 1 | awk -v dir="$root" '{print $1 " free of " $2 " on " dir}')
else
    storage="no disk set up yet"
fi

# Docker status
if ! docker_configured; then
    docker_status="not installed"
elif systemctl is-active --quiet docker 2>/dev/null; then
    docker_status="running ($(docker --version | awk '{print $3}' | tr -d ,))"
else
    docker_status="installed, not running"
fi

# Installed apps
ip=$(primary_ip)
apps=""
if [ -s "$APPS_FILE" ]; then
    while read -r id; do
        apps+="$(app_field "$id" APP_NAME)  http://$ip:$(app_port "$id")"$'\n'
    done < "$APPS_FILE"
    apps=${apps%$'\n'}
fi

# Backup status
backup=$(backup_last)
if [ -z "$backup" ]; then
    backup_status="not set up"
else
    backup_status="$backup"
fi

# Setup status
if [ -f "$SETUP_DONE" ]; then
    setup_status="finished"
else
    setup_status="not finished"
fi


cat <<BANNER

  _  __     _   _    _    ____
 | |/ /    | \ | |  / \  / ___|
 | ' /_____|  \| | / _ \ \___ \\
 | . \_____| |\  |/ ___ \ ___) |
 |_|\_\    |_| \_/_/   \_\____/

 Own your things locally!  v$KNAS_VERSION

 Welcome, ${USER:-$(id -un)}

 Address  : $(sed '2,$s/^/            /' <<< "${addresses:-no network address}")
 Storage  : $storage
 Docker   : $docker_status
 Backup   : $backup_status
 Apps     : $(sed '2,$s/^/            /' <<< "${apps:-none installed}")
 Setup    : $setup_status

BANNER


# While setup is not finished, offer to open it
if [ ! -f "$SETUP_DONE" ] && [ -t 0 ]; then
    read -r -p " Open the setup menu now? [Y/n] " answer
    case "$answer" in
        [nN]*)
            echo
            echo " Open it later with: sudo $KNAS_DIR/setup.sh"
            echo
            ;;
        *)
            sudo "$KNAS_DIR/setup.sh"
            ;;
    esac
else
    echo " Setup menu: sudo $KNAS_DIR/setup.sh"
    echo
fi
