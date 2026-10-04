#!/bin/bash

# Turns a plain Debian into K-NAS. Run as root by late-command.sh or install.sh.
# Safe to run again: existing stacks are kept.

set -eu

KNAS_DIR="/opt/k-nas"
STACKS_DIR="/opt/stacks"

export DEBIAN_FRONTEND=noninteractive


# 1. Docker (official repo)
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $VERSION_CODENAME stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin


# 2. Cockpit on port 9090. Backports has the Files page. No recommends: avoids NetworkManager.
echo "deb http://deb.debian.org/debian $VERSION_CODENAME-backports main" > /etc/apt/sources.list.d/backports.list
apt-get update
apt-get install -y --no-install-recommends -t "$VERSION_CODENAME-backports" \
    cockpit-ws cockpit-system cockpit-bridge cockpit-storaged cockpit-packagekit cockpit-files


# 3. Automatic security updates
apt-get install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF


# 4. App stacks (Dockge manages this folder)
mkdir -p "$STACKS_DIR"
for stack in "$KNAS_DIR"/stacks/*/; do
    name=$(basename "$stack")
    [ -e "$STACKS_DIR/$name" ] || cp -r "$stack" "$STACKS_DIR/$name"
done

# Random passwords, made once
for env_file in "$STACKS_DIR"/*/.env; do
    if grep -q '=change-me$' "$env_file"; then
        sed -i "s/=change-me$/=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')/" "$env_file"
        chmod 600 "$env_file"
    fi
done


# 5. Start the core apps at every boot
ln -sf "$KNAS_DIR/os/k-nas.service" /etc/systemd/system/k-nas.service
systemctl enable k-nas.service

# No systemd during the ISO install: apps start at first boot
if [ -d /run/systemd/system ]; then
    systemctl daemon-reload
    echo "Starting the apps (first time takes a few minutes)..."
    systemctl start k-nas.service
    cat /etc/issue.d/k-nas.issue
fi
