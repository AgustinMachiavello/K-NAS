#!/usr/bin/env bats

# Facts repeated in several files that cannot share code: these fail if the copies disagree

setup() {
    ROOT="$BATS_TEST_DIRNAME/.."
}

# Value of a preseed line: preseed_value passwd/username
preseed_value() {
    awk -v key="$1" '$1 == "d-i" && $2 == key {print $4; exit}' "$ROOT/os/debian/preseed.cfg"
}

@test "install folder is the same everywhere" {
    for file in install.sh os/setup.sh os/k-nas.service os/debian/late-command.sh; do
        paths=$(grep -o '/opt/k[A-Za-z0-9._-]*' "$ROOT/$file" | sort -u)
        [ "$paths" = "/opt/k-nas" ] || { echo "$file uses '$paths'"; return 1; }
    done
}

@test "the preseed runs late-command.sh from where build-iso.sh puts it" {
    grep -q 'tar -C /tmp/iso/k-nas' "$ROOT/os/debian/build-iso.sh"
    grep -q 'late_command string sh /cdrom/k-nas/os/debian/late-command.sh$' "$ROOT/os/debian/preseed.cfg"
}

@test "README title shows the version" {
    grep -qF "# K-NAS v$(cat "$ROOT/VERSION")" "$ROOT/README.md"
}

@test "README and install.sh use the same repository" {
    eval "$(grep "^KNAS_REPO=" "$ROOT/install.sh")"
    grep -qF "raw.githubusercontent.com/$KNAS_REPO/main/install.sh" "$ROOT/README.md"
    grep -qF "raw.githubusercontent.com/$KNAS_REPO/main/install.sh" "$ROOT/install.sh"
}

@test "the installer asks for the login: no username or password is preseeded" {
    [ -z "$(preseed_value passwd/username)" ]
    [ -z "$(preseed_value passwd/user-password)" ]
    # priority=high shows the questions that are not preseeded
    grep -q 'priority=high' "$ROOT/os/debian/build-iso.sh"
}

@test "every core stack started at boot exists" {
    stacks=$(sed -n 's/^CORE_STACKS="\(.*\)"/\1/p' "$ROOT/os/boot.sh")
    [ -n "$stacks" ]
    for stack in $stacks; do
        [ -f "$ROOT/stacks/$stack/compose.yaml" ] || { echo "missing stacks/$stack/compose.yaml"; return 1; }
    done
}

@test "every Homepage link points to a port an app publishes (or Cockpit's 9090)" {
    ports=$(cat "$ROOT"/stacks/*/compose.yaml | sed -n 's/^ *- "\([0-9]*\):[0-9]*"$/\1/p')
    for port in $(grep -o 'HOST}}:[0-9]*' "$ROOT/stacks/homepage/config/services.yaml" | cut -d: -f2); do
        [ "$port" = 9090 ] && continue
        echo "$ports" | grep -qx "$port" || { echo "no stack publishes port $port"; return 1; }
    done
}

@test "every password in the stacks is a placeholder that setup.sh makes random" {
    grep -q '^DB_PASSWORD=change-me$' "$ROOT/stacks/immich/.env"
    grep -q '^PIHOLE_PASSWORD=change-me$' "$ROOT/stacks/pihole/.env"
    grep -q "=change-me\\$" "$ROOT/os/setup.sh"
}
