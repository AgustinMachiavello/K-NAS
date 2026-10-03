#!/bin/bash

# Load K-NAS common code
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Status marks for the menu
source "$KNAS_DIR/status.sh"

# Only one setup at a time: two at once could leave a half-done state
exec 9>/run/k-nas.lock
if ! flock -n 9; then
    error "Another K-NAS setup is already running."
    exit 1
fi


# Run a step, and stop Quick setup if it did not work. Usage: quick_step script check_function "message"
quick_step() {
    KNAS_QUICK=1 "$KNAS_DIR/$1" || true
    if ! "$2"; then
        error "$3 Quick setup stopped."
        return 1
    fi
}

# Quick setup: the same steps as the menu, run in order with their default answers.
# Erasing a disk still asks you to choose it and type its name.
quick_setup() {

    if ! confirm "Quick setup will run these steps in order:

1. Add the main data disk (you choose it and confirm)
2. Install Docker
3. Install the default apps

Continue?"
    then
        return
    fi

    quick_step storage.sh storage_configured "No data disk is mounted." || return
    quick_step docker.sh docker_configured "Docker is not installed." || return
    KNAS_QUICK=1 "$KNAS_DIR/apps.sh" || true

    info "Quick setup finished.

Next: add a second disk and set up a backup. Your NAS is reachable by name (see the welcome screen). To keep its IP address fixed, reserve it in your router."
}


# Keep showing the main menu
while true; do

    # Show the main menu
    if ! choice=$(KNAS_MENU_HEIGHT=22 KNAS_MENU_ITEMS=10 menu \
        "Quick setup does steps 1 to 3 for you." \
        "quick" "Quick setup (recommended)" \
        "1" "$(mark storage_configured) Add a disk" \
        "2" "$(mark docker_configured) Install Docker" \
        "3" "$(mark apps_configured) Install apps" \
        "4" "$(mark backup_configured) Backups" \
        "5" "Import data from another disk" \
        "check" "Check everything" \
        "reset" "Repair / reset" \
        "finish" "Finish setup (stop opening at login)" \
        "exit" "Exit"
    ); then
        exit 0
    fi

    # Run the script for the selected option
    case "$choice" in

        quick)
            quick_setup
            ;;

        1)
            "$KNAS_DIR/storage.sh" || true
            ;;

        2)
            "$KNAS_DIR/docker.sh" || true
            ;;

        3)
            "$KNAS_DIR/apps.sh" || true
            ;;

        4)
            "$KNAS_DIR/backup.sh" || true
            ;;

        5)
            "$KNAS_DIR/import.sh" || true
            ;;

        check)
            "$KNAS_DIR/doctor.sh" | whiptail --title "$KNAS_TITLE" --textbox /dev/stdin 20 74
            ;;

        reset)
            "$KNAS_DIR/reset.sh" || true
            ;;

        finish)
            # The welcome screen (main.sh) stops offering to open this menu
            mkdir -p "$KNAS_STATE_DIR"
            touch "$SETUP_DONE"
            info "Setup finished. This menu will no longer open at login.

Run 'sudo $KNAS_DIR/setup.sh' to open it again."
            exit 0
            ;;

        exit)
            exit 0
            ;;

    esac

done
