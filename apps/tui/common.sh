#!/bin/bash

# Stop the script if a command fails
set -e

# Get the folder where K-NAS is located
KNAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load config
source "$KNAS_DIR/config.sh"

# Check that the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Check that whiptail is installed
if ! command -v whiptail >/dev/null 2>&1; then
    echo "whiptail is required."
    echo "Install it with: apt install whiptail"
    exit 1
fi


# Show an information message
info() {
    whiptail \
        --title "$KNAS_TITLE" \
        --msgbox "$1" \
        10 60
}


# Show an error message
error() {
    whiptail \
        --title "$KNAS_TITLE" \
        --msgbox "$1" \
        10 60
}


# Ask the user for text
input() {
    whiptail \
        --title "$KNAS_TITLE" \
        --inputbox "$1" \
        10 60 \
        "$2" \
        3>&1 1>&2 2>&3
}


# Ask the user a yes/no question
confirm() {
    whiptail \
        --title "$KNAS_TITLE" \
        --yesno "$1" \
        15 60
}


# Show a menu and return the selected option
menu() {
    whiptail \
        --title "$KNAS_TITLE" \
        --menu "$1" \
        15 60 5 \
        "${@:2}" \
        3>&1 1>&2 2>&3
}