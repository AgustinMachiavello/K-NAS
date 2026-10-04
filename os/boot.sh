#!/bin/bash

# Runs at every boot (k-nas.service), after Docker: shows the NAS IP, starts the core apps.

set -eu

STACKS_DIR="/opt/stacks"
CORE_STACKS="homepage dockge backrest"

# The IP other devices use to reach the NAS
ip=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')
ip=${ip:-127.0.0.1}

# Shown above the login prompt
mkdir -p /etc/issue.d
printf 'K-NAS is ready. Open http://%s:3000 on any device in your home.\n\n' "$ip" > /etc/issue.d/k-nas.issue
agetty --reload 2>/dev/null || true

# Homepage builds its links from this file
host_file="$STACKS_DIR/homepage/config/host"
old_ip=$(cat "$host_file" 2>/dev/null || true)
printf '%s' "$ip" > "$host_file"

# No-op if already running
for stack in $CORE_STACKS; do
    docker compose -f "$STACKS_DIR/$stack/compose.yaml" up -d
done

# IP changed: restart Homepage so its links follow
if [ -n "$old_ip" ] && [ "$old_ip" != "$ip" ]; then
    docker compose -f "$STACKS_DIR/homepage/compose.yaml" restart
fi
