#!/bin/bash

# Load K-NAS common code
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Status checks and the Homepage links
source "$KNAS_DIR/status.sh"
source "$KNAS_DIR/homepage-lib.sh"

# Show an error if any command below fails
fail_on_error "Apps setup failed unexpectedly. Check the output above.

Run 'Repair / reset' in the setup menu if needed."




# Apps store their data on the main data disk and run in Docker
STORAGE_DIR=$(storage_root)
if [ -z "$STORAGE_DIR" ] || ! docker_configured; then
    error "Apps need the data disk and Docker.

Add a disk and install Docker first, or use Quick setup."
    exit 1
fi


# Nothing to install if there are no apps yet
if ! compgen -G "$KNAS_SERVICES_DIR/*/app.conf" >/dev/null; then
    info "There are no apps available yet."
    exit 0
fi


# Build the list of apps, one line each, ticked by default if the app says so
ITEMS=()
DEFAULTS=""
for dir in "$KNAS_SERVICES_DIR"/*/; do
    id=$(basename "$dir")
    label="$(app_field "$id" APP_NAME) - $(app_field "$id" APP_DESCRIPTION)"
    state=$(app_field "$id" APP_DEFAULT)

    if app_installed "$id"; then
        label="$label (installed)"
        state="off"
    fi

    ITEMS+=("$id" "$label" "${state:-off}")
    [ "$state" = "on" ] && DEFAULTS+="$id"$'\n'
done


# Quick mode installs the default apps. Otherwise let the user choose
if quick_mode; then
    SELECTED="${DEFAULTS%$'\n'}"
else
    SELECTED=$(checklist "Select the apps to install (Space to tick, Enter to confirm):" "${ITEMS[@]}") || exit 0
fi

if [ -z "$SELECTED" ]; then
    info "No apps to install. Nothing was changed."
    exit 0
fi


# Run the apps as the normal user, so files on the storage disk belong to them
export STORAGE_DIR
PUID=$(id -u "$KNAS_USER")
PGID=$(id -g "$KNAS_USER")
export PUID PGID

IP=$(primary_ip)
RESULT=""
FAILED=0

clear
# The list comes in on fd 3, so the dialogs below still read the keyboard
while read -r id <&3; do
    name=$(app_field "$id" APP_NAME)

    # Warn before installing an app on a machine with too little memory
    min_ram=$(app_field "$id" APP_MIN_RAM_MB)
    ram=$(awk '/^MemTotal/ {print int($2 / 1024)}' /proc/meminfo)
    if [ -n "$min_ram" ] && [ "$ram" -lt "$min_ram" ] && ! confirm "$name needs about $min_ram MB of memory and this machine has $ram MB.

It may be very slow or stop working. Install it anyway?"
    then
        RESULT+="$name: skipped, not enough memory
"
        continue
    fi

    echo "=== $name"

    # The compose file reads these
    port=$(app_port "$id")
    data="$STORAGE_DIR/docker/$id"

    # Create the data folders first, otherwise Docker creates them as root.
    mkdir -p "$data"
    for folder in $(app_field "$id" APP_DIRS); do
        if [ ! -d "$data/$folder" ]; then
            mkdir -p "$data/$folder"
            chown "$KNAS_USER:$KNAS_USER" "$data/$folder"
        fi
    done

    # Random secrets the app needs (a database password, for example), made once and then reused.
    # They are kept next to the app's data, readable by root only. They are not your K-NAS password.
    secrets="$data/.secrets.env"
    for secret in $(app_field "$id" APP_SECRETS); do
        if ! grep -q "^$secret=" "$secrets" 2>/dev/null; then
            ( umask 077; echo "$secret=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)" >> "$secrets" )
        fi
    done
    env_file=()
    [ -f "$secrets" ] && env_file=(--env-file "$secrets")

    # This command is in an "if", so a failure does not stop the other apps
    if KNAS_HOSTNAME="$(hostname).local" KNAS_IP="$IP" APP_PORT="$port" APP_DATA="$data" docker compose "${env_file[@]}" -p "k-nas-$id" -f "$KNAS_SERVICES_DIR/$id/docker-compose.yml" up -d < /dev/null; then
        mkdir -p "$(dirname "$APPS_FILE")"
        grep -qx "$id" "$APPS_FILE" 2>/dev/null || echo "$id" >> "$APPS_FILE"
        chmod 644 "$APPS_FILE"
        note=$(app_field "$id" APP_NOTE)
        RESULT+="$name: http://$IP:$port${note:+
  $note}
"
    else
        FAILED=1
        RESULT+="$name: FAILED, see the output above
"
    fi
done 3<<< "$SELECTED"


# Add the installed apps to the Homepage start page (a problem here must not fail the install)
homepage_update || true

if [ "$FAILED" -eq 0 ]; then
    info "Apps started:

$RESULT"
else
    error "Some apps did not start:

$RESULT"
    exit 1
fi
