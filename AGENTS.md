# AGENTS.md

Personal collection of standalone Bash helpers in `bin/`. No shared library, no build step: each
script stands alone, `install.sh` symlinks every `bin/*` entry into `~/.local/bin`, and `tests/`
holds a bats suite.

## Commands

- `mise install` — installs the pinned tools (`bats`, `shellcheck`, `prek`, `bump-my-version`).
- `mise run lint` — `prek run --all-files` over `.pre-commit-config.yaml` (shellcheck, yamllint,
  whitespace/EOF/line-ending fixers). Some hooks rewrite files, so re-run after editing.
- `mise run test` — `bats --print-output-on-failure tests`.
- Single file or case: `bats tests/ftenv.bats`, `bats --filter 'missing' tests/ftenv.bats`.
- CI runs exactly these two tasks on PRs and pushes to `main` (`.github/workflows/`).

## Testing

- Only `bin/ftenv` has tests. Add `tests/<basename>.bats` once a new script carries real logic.
- Follow `tests/ftenv.bats`: `setup`/`teardown` around `mktemp -d`, then run the script under test
  as `bash "$BATS_TEST_DIRNAME/../bin/<name>"`; assert on `status`, `output`, and `stderr`.
- `install.sh` symlinks rather than copies, so edits under `bin/` reach the installed command
  immediately; only new files need another `./install.sh`.
- Scripts needing root or real hardware (PulseAudio, X11, LUKS, resticprofile) get lint plus a
  manual run, not CI tests; do not mock them into the suite.

## Script conventions

Follow the `bash-scripting` skill for all Bash work (`function name()` with the brace on its own
line, `main "$@"`, quoting, `: "${VAR:=default}"` defaults). Repo-specific notes:

- `mise run lint` is the style gate; indent 4 spaces (`.editorconfig` covers `*.sh` and `bin/*`).
- Start with `#!/usr/bin/env bash`, `set -o pipefail`, and `set -u`; no `set -e` in new scripts.
  `rp-pruner.sh` and `notify-send-as-user.sh` predate this rule; leave them as they are.
- Diagnostics go to stderr through a per-script `_msg` helper (`_info`/`_error` where present).
  Helpers are copied per script, never sourced from a sibling script.
- Every file in `bin/` gets symlinked into `~/.local/bin`, so keep helpers and data out of it; each
  entry must be executable and start with a shebang (`check-executables-have-shebangs` hook).
- `move-to-next-monitor.sh` keeps its legacy `/bin/bash` shebang; do not "fix" it.

## Releases

- Write the release bullets under `## Unreleased` in `CHANGELOG.md` by hand (no git-cliff here),
  then run `mise run bump-version:{major,minor,patch}`. bump-my-version rewrites `CHANGELOG.md`,
  commits, and tags `vX.Y.Z`; no other file records the version.
- `mise run git-push` pushes the branch together with tags.

## Commits

Conventional Commits; the scope is the script basename without `.sh` (`fix(manage-audio): ...`,
`refactor(rp-pruner): ...`), or `install`/`.github` for repo infrastructure.

## Config ownership

`.editorconfig`, `.gitignore`, `.pre-commit-config.yaml`, `.yamllint.yaml`, `mise.toml`, and
`.bumpversion.toml` derive from the `git-repo-scaffold` skill's `templates/common/`. This repo
deliberately diverges (bats tasks, per-part bump tasks, no git-cliff), so merge template updates
by hand rather than copying files over.
