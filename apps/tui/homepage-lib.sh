#!/bin/bash

# Keeps the Homepage start page up to date with one link per installed app.
# Homepage reads <disk>/docker/homepage/config/services.yaml and reloads it by itself.

# Quote a value for YAML
yaml_quote() {
    local value="${1//\\/\\\\}"
    echo "\"${value//\"/\\\"}\""
}

# Print services.yaml for the entries on stdin, one per line.
homepage_services_yaml() {
    local name description url
    echo "# Written by K-NAS (apps/tui/homepage-lib.sh). Changes here are overwritten when apps change."
    echo "- K-NAS:"
    while IFS='|' read -r name description url; do
        [ -n "$name" ] || continue
        echo "    - $(yaml_quote "$name"):"
        echo "        href: $(yaml_quote "$url")"
        echo "        description: $(yaml_quote "$description")"
    done
}

# Write services.yaml from the installed apps. Does nothing if Homepage is not installed.
homepage_update() {
    local host id root
    app_installed homepage || return 0

    root=$(storage_root)
    [ -n "$root" ] || return 0
    host=$(primary_ip)
    [ -n "$host" ] || return 0

    {
        while read -r id; do
            [ "$id" = "homepage" ] && continue
            echo "$(app_field "$id" APP_NAME)|$(app_field "$id" APP_DESCRIPTION)|http://$host:$(app_port "$id")"
        done < "$APPS_FILE"
    } | homepage_services_yaml > "$root/docker/homepage/config/services.yaml"
}
