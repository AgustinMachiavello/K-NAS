#!/bin/bash

# Load K-NAS common code
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Keep showing the main menu
while true; do

    # Show the main menu
    if ! choice=$(menu \
        "What would you like to configure?" \
        "network" "Configure network" \
        "exit" "Exit"
    ); then
        exit 0
    fi

    # Run the script for the selected option
    case "$choice" in

        network)
            "$KNAS_DIR/network.sh"
            ;;

        exit)
            exit 0
            ;;

    esac

done