#!/bin/bash

# Load K-NAS common code
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"


# Get all network interfaces except loopback
INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$')

# Check that at least one interface was found
if [ -z "$INTERFACES" ]; then
    error "No network interfaces were found."
    exit 1
fi


# Build the interface menu
MENU_ITEMS=()

for interface in $INTERFACES; do
    MENU_ITEMS+=("$interface" "Network interface")
done


# Let the user choose an interface
if ! INTERFACE=$(menu \
    "Select the network interface:" \
    "${MENU_ITEMS[@]}"
); then
    exit 0
fi


# Ask for the static IP
IP=$(input \
    "Enter the static IP address:" \
    "192.168.0.77"
)


# Ask for the netmask
NETMASK=$(input \
    "Enter the netmask:" \
    "255.255.255.0"
)


# Ask for the gateway
GATEWAY=$(input \
    "Enter the gateway:" \
    "192.168.0.1"
)


# Ask for the DNS servers
DNS=$(input \
    "Enter the DNS servers:" \
    "192.168.0.1 8.8.8.8"
)


# Show the configuration before applying it
if ! confirm "Network configuration:

Interface: $INTERFACE
IP address: $IP
Netmask: $NETMASK
Gateway: $GATEWAY
DNS: $DNS

Apply this configuration?"
then
    exit 0
fi


# Back up the current network configuration
cp /etc/network/interfaces /etc/network/interfaces.knas-backup


# Create the new network configuration
cat > /etc/network/interfaces <<EOF
# Loopback interface
auto lo
iface lo inet loopback

# K-NAS network interface
allow-hotplug $INTERFACE

iface $INTERFACE inet static
    address $IP
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS
EOF


# Restart networking
systemctl restart networking


# Check that the interface has the configured IP
if ip addr show "$INTERFACE" | grep -q "$IP"; then

    info "Network configured successfully.

Interface: $INTERFACE
IP address: $IP"

else

    error "The network configuration may have failed.

The previous configuration was backed up to:

/etc/network/interfaces.knas-backup"

    exit 1

fi