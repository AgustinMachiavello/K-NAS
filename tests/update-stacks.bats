#!/usr/bin/env bats

# Tests for os/update-stacks.sh, on temporary folders

setup() {
    ROOT="$BATS_TEST_DIRNAME/.."
    export KNAS_DIR="$BATS_TEST_TMPDIR/k-nas"
    export STACKS_DIR="$BATS_TEST_TMPDIR/stacks"
    export BASE_DIR="$BATS_TEST_TMPDIR/base"
    mkdir -p "$KNAS_DIR/stacks/app/config"
    echo "v1" > "$KNAS_DIR/stacks/app/compose.yaml"
    echo "links v1" > "$KNAS_DIR/stacks/app/config/services.yaml"
    echo "PASSWORD=change-me" > "$KNAS_DIR/stacks/app/.env"
    # No Docker in tests: nothing is restarted
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/docker"
    chmod +x "$BATS_TEST_TMPDIR/bin/docker"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

update() {
    run bash "$ROOT/os/update-stacks.sh"
    [ "$status" -eq 0 ]
}

# A new version of the stack in the repo
release_v2() {
    echo "v2" > "$KNAS_DIR/stacks/app/compose.yaml"
    echo "links v2" > "$KNAS_DIR/stacks/app/config/services.yaml"
}

@test "copies a new stack whole" {
    update
    [ "$(cat "$STACKS_DIR/app/compose.yaml")" = "v1" ]
    [ -f "$STACKS_DIR/app/.env" ]
}

@test "updates files you have not changed" {
    update
    release_v2
    update
    [ "$(cat "$STACKS_DIR/app/compose.yaml")" = "v2" ]
    [ "$(cat "$STACKS_DIR/app/config/services.yaml")" = "links v2" ]
    [ ! -e "$STACKS_DIR/app/compose.yaml.before-update" ]
}

@test "keeps files you changed and leaves the new version next to them" {
    update
    echo "mine" > "$STACKS_DIR/app/compose.yaml"
    release_v2
    update
    [ "$(cat "$STACKS_DIR/app/compose.yaml")" = "mine" ]
    [ "$(cat "$STACKS_DIR/app/compose.yaml.k-nas-new")" = "v2" ]
}

@test "never replaces .env" {
    update
    echo "PASSWORD=secret" > "$STACKS_DIR/app/.env"
    echo "PASSWORD=other" > "$KNAS_DIR/stacks/app/.env"
    update
    [ "$(cat "$STACKS_DIR/app/.env")" = "PASSWORD=secret" ]
}

@test "stacks installed before updates existed: updated, with a copy of the old file" {
    mkdir -p "$STACKS_DIR/app"
    echo "v0" > "$STACKS_DIR/app/compose.yaml"
    update
    [ "$(cat "$STACKS_DIR/app/compose.yaml")" = "v1" ]
    [ "$(cat "$STACKS_DIR/app/compose.yaml.before-update")" = "v0" ]
}

@test "adds files new to an existing stack" {
    update
    echo "new" > "$KNAS_DIR/stacks/app/config/widgets.yaml"
    update
    [ "$(cat "$STACKS_DIR/app/config/widgets.yaml")" = "new" ]
}
