#!/usr/bin/env bats

# Tests for os/debian/late-command.sh, on temporary folders

setup() {
    ROOT="$BATS_TEST_DIRNAME/.."
    export TARGET="$BATS_TEST_TMPDIR/target"
    export SRC="$BATS_TEST_TMPDIR/src"
    # Print the command instead of running it
    export IN_TARGET="echo in-target:"
    mkdir -p "$TARGET" "$SRC/os"
    echo '#!/bin/bash' > "$SRC/os/setup.sh"
}

@test "copies K-NAS to /opt/k-nas and makes the scripts executable" {
    run sh "$ROOT/os/debian/late-command.sh"
    [ "$status" -eq 0 ]
    [ -x "$TARGET/opt/k-nas/os/setup.sh" ]
}

@test "runs setup.sh inside the installed system" {
    run sh "$ROOT/os/debian/late-command.sh"
    [ "$output" = "in-target: bash /opt/k-nas/os/setup.sh" ]
}

@test "works with a minimal POSIX shell (the installer has no bash)" {
    if ! command -v dash >/dev/null; then skip "dash is not installed"; fi
    run dash "$ROOT/os/debian/late-command.sh"
    [ "$status" -eq 0 ]
}
