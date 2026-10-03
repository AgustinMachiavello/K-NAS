#!/bin/bash

# Stop the script if a command fails
set -e

# Get the folder where K-NAS is located
KNAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load config
source "$KNAS_DIR/config.sh"

# Pure helpers
source "$KNAS_DIR/lib.sh"

# Quick mode (set by "Quick setup")
quick_mode() {
    [ "${KNAS_QUICK:-0}" = "1" ]
}

# Check that the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Normal user that owns the K-NAS files (the user who ran sudo, or the first user)
KNAS_USER="${SUDO_USER:-$(getent passwd 1000 | cut -d: -f1)}"

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
    info "$1"
}


# Show an error message and stop the script if any command after this fails.
# Optional second argument: a command to run first, to undo a half-done change.
# Usage: fail_on_error "Setup failed." [cleanup_command]
fail_on_error() {
    KNAS_FAIL_MESSAGE="$1"
    KNAS_FAIL_CLEANUP="${2:-}"
    trap '[ -n "$KNAS_FAIL_CLEANUP" ] && $KNAS_FAIL_CLEANUP; error "$KNAS_FAIL_MESSAGE"; exit 1' ERR
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
        "${KNAS_MENU_HEIGHT:-15}" "${KNAS_MENU_WIDTH:-60}" "${KNAS_MENU_ITEMS:-5}" \
        "${@:2}" \
        3>&1 1>&2 2>&3
}


# Show a checklist and print the ticked options, one per line.
# Usage: checklist "question" tag "description" on|off ...
checklist() {
    whiptail \
        --title "$KNAS_TITLE" \
        --separate-output \
        --checklist "$1" \
        18 76 6 \
        "${@:2}" \
        3>&1 1>&2 2>&3
}
