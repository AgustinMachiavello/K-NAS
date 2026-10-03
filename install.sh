#!/bin/bash

# K-NAS installer for an existing Debian system.
# Usage: curl -fsSL https://raw.githubusercontent.com/AgustinMachiavello/K-NAS/main/install.sh | sudo bash

# Stop the script if a command fails
set -e

# Where K-NAS is downloaded from and installed to
KNAS_REPO="AgustinMachiavello/K-NAS"
KNAS_TARBALL="https://github.com/$KNAS_REPO/archive/refs/heads/main.tar.gz"
KNAS_INSTALL_DIR="/opt/k-nas"

# Check that the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Example: curl -fsSL <url> | sudo bash"
    exit 1
fi

# Check that this is Debian
. /etc/os-release
if [ "$ID" != "debian" ]; then
    echo "K-NAS only supports Debian for now (found: ${PRETTY_NAME:-unknown})."
    exit 1
fi

# Install the tools K-NAS needs
if ! command -v whiptail >/dev/null 2>&1 || ! dpkg -s avahi-daemon >/dev/null 2>&1; then
    echo "Installing whiptail and avahi-daemon..."
    apt-get update -qq
    apt-get install -y -qq whiptail avahi-daemon
fi

# Download K-NAS (replaces any previous copy)
echo "Downloading K-NAS to $KNAS_INSTALL_DIR..."
rm -rf "$KNAS_INSTALL_DIR"
mkdir -p "$KNAS_INSTALL_DIR"
curl -fsSL "$KNAS_TARBALL" | tar -xz -C "$KNAS_INSTALL_DIR" --strip-components=1
chmod +x "$KNAS_INSTALL_DIR"/apps/tui/*.sh

# Show the K-NAS welcome screen at every login
ln -sf "$KNAS_INSTALL_DIR/apps/tui/login-hook.sh" /etc/profile.d/k-nas.sh

# Start the TUI. Reconnect the keyboard.
exec "$KNAS_INSTALL_DIR/apps/tui/setup.sh" < /dev/tty
