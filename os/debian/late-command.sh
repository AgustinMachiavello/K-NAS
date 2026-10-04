#!/bin/sh

# Runs at the end of the Debian install. POSIX sh: the installer has no bash.

SRC="${SRC:-/cdrom/k-nas}"
TARGET="${TARGET:-/target}"
# Tests replace this
IN_TARGET="${IN_TARGET:-in-target}"

set -e

# Copy K-NAS to the new system
mkdir -p "$TARGET/opt/k-nas"
cp -r "$SRC/." "$TARGET/opt/k-nas/"
chmod +x "$TARGET"/opt/k-nas/os/*.sh

# Install everything inside it
$IN_TARGET bash /opt/k-nas/os/setup.sh
