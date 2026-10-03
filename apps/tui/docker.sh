#!/bin/bash

# Load K-NAS common code
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Status checks
source "$KNAS_DIR/status.sh"

# Keep going if the SSH connection drops, so the install is not cut in half
trap '' HUP

fail_on_error "Docker installation failed. Check the output above.

Run 'Repair / reset' in the setup menu, then try this step again."


# Nothing to do if Docker is already installed
if docker_configured; then
    quick_mode || info "Docker is already installed:

$(docker --version)"
    exit 0
fi


# Ask before installing (quick mode already asked at the start)
if ! quick_mode && ! confirm "Install Docker Engine and Docker Compose from Docker's official repository?"; then
    exit 0
fi


clear
export DEBIAN_FRONTEND=noninteractive

# Install the tools needed to download and verify Docker's packages
apt-get update
apt-get install -y ca-certificates curl gnupg

# Add Docker's official signing key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker's repository, matched to this Debian version
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $VERSION_CODENAME stable" \
    > /etc/apt/sources.list.d/docker.list

# Install Docker, its CLI, the container runtime and Docker Compose
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


# Check that Docker works
if docker run --rm hello-world >/dev/null 2>&1; then
    info "Docker installed successfully.

$(docker --version)"
else
    error "Docker was installed, but the test container failed to run."
    exit 1
fi
