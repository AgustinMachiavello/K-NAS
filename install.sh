#!/bin/bash

# K-NAS installer for an existing Debian.
# Usage: curl -fsSL https://raw.githubusercontent.com/AgustinMachiavello/K-NAS/main/install.sh | sudo bash

set -e

KNAS_REPO="AgustinMachiavello/K-NAS"
KNAS_TARBALL="https://github.com/$KNAS_REPO/archive/refs/heads/main.tar.gz"
KNAS_INSTALL_DIR="/opt/k-nas"

# Must be root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Example: curl -fsSL <url> | sudo bash"
    exit 1
fi

# Must be Debian
. /etc/os-release
if [ "$ID" != "debian" ]; then
    echo "K-NAS only supports Debian for now (found: ${PRETTY_NAME:-unknown})."
    exit 1
fi

# Replace the old copy (apps in /opt/stacks are kept)
echo "Downloading K-NAS to $KNAS_INSTALL_DIR..."
rm -rf "$KNAS_INSTALL_DIR"
mkdir -p "$KNAS_INSTALL_DIR"
curl -fsSL "$KNAS_TARBALL" | tar -xz -C "$KNAS_INSTALL_DIR" --strip-components=1
chmod +x "$KNAS_INSTALL_DIR"/os/*.sh

exec "$KNAS_INSTALL_DIR/os/setup.sh"
