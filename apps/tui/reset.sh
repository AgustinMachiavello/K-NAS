#!/bin/bash

# Repair and reset: get back to a clean state when a setup step failed or was interrupted.
# Nothing here erases data on your disks.

# Load K-NAS common code
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Status checks
source "$KNAS_DIR/status.sh"

# One action failing returns to the menu with a message, instead of closing it
fail_on_error "That action failed. Check the output above."


# Finish a package install that was cut in half
repair_packages() {
    clear
    dpkg --configure -a
    apt-get -f install -y
    info "Package repair finished. Run the step that failed again."
}

# Stop and remove the K-NAS apps containers. Their data folders are kept.
remove_apps() {
    local id
    if ! apps_configured; then
        info "No K-NAS apps are installed."
        return
    fi

    if ! confirm "Stop and remove the K-NAS apps?

Their data folders are kept, so installing them again brings the data back."
    then
        return
    fi

    clear
    while read -r id; do
        docker compose -p "k-nas-$id" -f "$KNAS_SERVICES_DIR/$id/docker-compose.yml" down < /dev/null || true
    done < "$APPS_FILE"
    forget_setup_state_apps
    info "K-NAS apps removed. Their data folders are kept."
}

# Forget only the list of installed apps
forget_setup_state_apps() {
    rm -f "$APPS_FILE"
}

# Forget the setup progress marks, so the welcome screen offers the setup again
reset_progress() {
    if confirm "Forget the setup progress?

The welcome screen offers the setup menu again. Installed software, apps and data are not touched."
    then
        forget_setup_state
        info "Setup progress forgotten."
    fi
}


while true; do

    if ! choice=$(KNAS_MENU_HEIGHT=15 KNAS_MENU_ITEMS=4 menu \
        "Nothing here erases data on your disks." \
        "1" "Repair interrupted package installs" \
        "2" "Stop and remove K-NAS apps (data is kept)" \
        "3" "Forget setup progress" \
        "back" "Back"
    ); then
        exit 0
    fi

    case "$choice" in
        1) repair_packages ;;
        2) remove_apps ;;
        3) reset_progress ;;
        back) exit 0 ;;
    esac

done
