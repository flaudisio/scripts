#!/usr/bin/env bats

# Secret files and `bash -c` payloads are written as literal strings on
# purpose, so `$VAR` must stay unexpanded in this test file itself.
# shellcheck disable=SC2016

bats_require_minimum_version 1.5.0

setup()
{
    TMP="$( mktemp -d )"
    FTENV="$BATS_TEST_DIRNAME/../bin/ftenv"
}

teardown()
{
    rm -rf "$TMP"
}

@test "loads variables from a single secret file" {
    printf 'export FOO=bar\n' > "$TMP/one.env"

    run bash "$FTENV" run --load "$TMP/one.env" -- bash -c 'echo "$FOO"'

    [ "$status" -eq 0 ]
    [ "$output" = "bar" ]
}

@test "loads every file directly inside a directory" {
    mkdir "$TMP/secrets"
    printf 'export A=1\n' > "$TMP/secrets/10-a.env"
    printf 'export B=2\n' > "$TMP/secrets/20-b.env"

    run bash "$FTENV" run --load "$TMP/secrets" -- bash -c 'echo "$A$B"'

    [ "$status" -eq 0 ]
    [ "$output" = "12" ]
}

@test "ignores subdirectories of a loaded directory" {
    mkdir -p "$TMP/secrets/sub"
    printf 'export A=kept\n' > "$TMP/secrets/a.env"
    printf 'export A=nested\n' > "$TMP/secrets/sub/b.env"

    run bash "$FTENV" run --load "$TMP/secrets" -- bash -c 'echo "$A"'

    [ "$status" -eq 0 ]
    [ "$output" = "kept" ]
}

@test "ignores hidden files in a loaded directory" {
    mkdir "$TMP/secrets"
    printf 'export HIDDEN=yes\n' > "$TMP/secrets/.hidden.env"
    printf 'export VISIBLE=yes\n' > "$TMP/secrets/visible.env"

    run bash "$FTENV" run --load "$TMP/secrets" -- bash -c 'echo "${HIDDEN:-unset}|$VISIBLE"'

    [ "$status" -eq 0 ]
    [ "$output" = "unset|yes" ]
}

@test "later --load wins over earlier --load" {
    printf 'export FOO=one\n' > "$TMP/a.env"
    printf 'export FOO=two\n' > "$TMP/b.env"

    run bash "$FTENV" run --load "$TMP/a.env" --load "$TMP/b.env" -- bash -c 'echo "$FOO"'

    [ "$status" -eq 0 ]
    [ "$output" = "two" ]
}

@test "does not clear variables already in the environment" {
    printf 'export LOADED=yes\n' > "$TMP/one.env"
    export CALLER=keep

    run bash "$FTENV" run --load "$TMP/one.env" -- bash -c 'echo "$CALLER|$LOADED"'

    [ "$status" -eq 0 ]
    [ "$output" = "keep|yes" ]
}

@test "preserves quoting inside a secret file" {
    printf 'export GREETING="hello world"\n' > "$TMP/greet.env"

    run bash "$FTENV" run --load "$TMP/greet.env" -- bash -c 'echo "$GREETING"'

    [ "$status" -eq 0 ]
    [ "$output" = "hello world" ]
}

@test "expands variables inside a secret file" {
    printf 'export BASE=/srv\nexport FULL="${BASE}/app"\n' > "$TMP/exp.env"

    run bash "$FTENV" run --load "$TMP/exp.env" -- bash -c 'echo "$FULL"'

    [ "$status" -eq 0 ]
    [ "$output" = "/srv/app" ]
}

@test "propagates the exit status of a failing command" {
    printf 'export FOO=bar\n' > "$TMP/one.env"

    run bash "$FTENV" run --load "$TMP/one.env" -- false

    [ "$status" -eq 1 ]
}

@test "propagates an explicit exit status" {
    printf 'export FOO=bar\n' > "$TMP/one.env"

    run bash "$FTENV" run --load "$TMP/one.env" -- bash -c 'exit 42'

    [ "$status" -eq 42 ]
}

@test "returns 127 for an unknown command" {
    printf 'export FOO=bar\n' > "$TMP/one.env"

    run -127 bash "$FTENV" run --load "$TMP/one.env" -- no-such-command-xyz

    [ "$status" -eq 127 ]
}

@test "fails with exit 1 when a --load path is missing" {
    run bash "$FTENV" run --load "$TMP/missing.env" -- true

    [ "$status" -eq 1 ]
    [[ "$output" == *"$TMP/missing.env"* ]]
}

@test "fails with exit 2 when -- is missing" {
    printf 'export FOO=bar\n' > "$TMP/one.env"

    run bash "$FTENV" run --load "$TMP/one.env"

    [ "$status" -eq 2 ]
}

@test "fails with exit 2 when no command follows --" {
    printf 'export FOO=bar\n' > "$TMP/one.env"

    run bash "$FTENV" run --load "$TMP/one.env" --

    [ "$status" -eq 2 ]
}

@test "fails with exit 2 when no --load is given" {
    run bash "$FTENV" run -- true

    [ "$status" -eq 2 ]
}

@test "fails with exit 2 on an unknown option" {
    run bash "$FTENV" run --bogus -- true

    [ "$status" -eq 2 ]
}

@test "--help exits 0" {
    run bash "$FTENV" --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "run --help exits 0" {
    run bash "$FTENV" run --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "passes arguments verbatim, including -- and spaces" {
    printf 'export FOO=bar\n' > "$TMP/one.env"

    run bash "$FTENV" run --load "$TMP/one.env" -- \
        bash -c 'for arg in "$@" ; do printf "[%s]\n" "$arg" ; done' _ -- "two words"

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "[--]" ]
    [ "${lines[1]}" = "[two words]" ]
}
