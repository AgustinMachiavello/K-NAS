#!/bin/bash

# Copies the repo's stacks to /opt/stacks. Run by setup.sh, so re-running the installer updates them.
# New stacks are copied whole. In existing stacks only compose.yaml and config/*.yaml are updated,
# and only if you have not changed them. .env files and app settings are never replaced.

set -eu

KNAS_DIR="${KNAS_DIR:-/opt/k-nas}"
STACKS_DIR="${STACKS_DIR:-/opt/stacks}"
# The repo version of each updated file, as last installed: tells your changes from ours
BASE_DIR="${BASE_DIR:-/var/lib/k-nas/stacks}"

# Stacks whose compose.yaml changed, to restart if running
changed_stacks=""

update_file() {
    local stack=$1 file=$2
    local repo="$KNAS_DIR/stacks/$stack/$file"
    local installed="$STACKS_DIR/$stack/$file"
    local base="$BASE_DIR/$stack/$file"

    if [ ! -e "$installed" ]; then
        mkdir -p "$(dirname "$installed")"
        cp "$repo" "$installed"
    elif cmp -s "$repo" "$installed"; then
        :  # Already up to date
    elif [ -e "$base" ] && ! cmp -s "$base" "$installed"; then
        # You changed it: keep yours, leave ours next to it
        cp "$repo" "$installed.k-nas-new"
        echo "Kept your $stack/$file. The new version is in $stack/$file.k-nas-new"
        return
    else
        # Installed before K-NAS kept track: no way to know if you changed it, so keep a copy
        if [ ! -e "$base" ]; then
            cp "$installed" "$installed.before-update"
        fi
        cp "$repo" "$installed"
        echo "Updated $stack/$file"
        if [ "$file" = compose.yaml ]; then
            changed_stacks="$changed_stacks $stack"
        fi
    fi

    mkdir -p "$(dirname "$base")"
    cp "$repo" "$base"
}

mkdir -p "$STACKS_DIR"
for stack_dir in "$KNAS_DIR"/stacks/*/; do
    stack=$(basename "$stack_dir")
    if [ ! -e "$STACKS_DIR/$stack" ]; then
        cp -r "$stack_dir" "$STACKS_DIR/$stack"
    fi

    for path in "$stack_dir"compose.yaml "$stack_dir"config/*.yaml; do
        if [ -f "$path" ]; then
            update_file "$stack" "${path#"$stack_dir"}"
        fi
    done
done

# Apply the new compose files to the stacks that are running (stopped ones get them on Start)
if [ -n "$changed_stacks" ] && docker info >/dev/null 2>&1; then
    running=$(docker compose ls -q)
    for stack in $changed_stacks; do
        if echo "$running" | grep -qx "$stack"; then
            echo "Restarting $stack with its new version..."
            docker compose -f "$STACKS_DIR/$stack/compose.yaml" up -d
        fi
    done
fi
