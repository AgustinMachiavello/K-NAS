#!/bin/sh

# Runs at the end of the Debian install

SRC="${SRC:-/cdrom/k-nas}"
TARGET="${TARGET:-/target}"

# 1. Copy K-NAS to the installed system
mkdir -p "$TARGET/opt/k-nas"
cp -r "$SRC/." "$TARGET/opt/k-nas/"
chmod +x "$TARGET"/opt/k-nas/apps/tui/*.sh

# 2. Show the K-NAS welcome screen at login.
mkdir -p "$TARGET/etc/profile.d"
ln -sf /opt/k-nas/apps/tui/login-hook.sh "$TARGET/etc/profile.d/k-nas.sh"
