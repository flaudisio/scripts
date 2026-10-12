# AGENTS.md

Personal collection of standalone Bash helper scripts. `install.sh` symlinks every `bin/*`
script into `~/.local/bin`. There is no shared library or build step; scripts are covered by
a bats suite under `tests/`.

## Commands

- `mise run lint` — runs `prek run --all-files` against `.pre-commit-config.yaml` (shellcheck,
  yamllint, whitespace/EOF fixers). Some hooks rewrite files in place, so re-run it after editing.
- `mise run test` — runs the `tests/*.bats` suite with bats.
- `mise install` — installs the pinned tools (`prek`, `shellcheck`, `bump-my-version`, `bats`).
- To verify a script, run it directly and pass `mise run lint`. Many scripts need root or real
  hardware (PulseAudio, X11, LUKS, restic) and cannot be exercised in CI.

## Script conventions

Load and follow the `bash-scripting` skill for all Bash work (shebang, `set -o pipefail` without
`set -e`, 4-space indent, `function name()` with the brace on its own line, `main "$@"`, quoting,
`: "${VAR:=default}"` defaults). Repo-specific deltas:

- Reuse the existing `_msg`/`_info`/`_error` helpers to send diagnostics to stderr.
- One legacy exception to the skill's shebang rule: `move-to-next-monitor.sh` uses `/bin/bash`.

## Releases

- `mise run bump-version:{major,minor,patch}` drives bump-my-version (`.bumpversion.toml`): it
  inserts the new version heading into `CHANGELOG.md`, commits, and tags `vX.Y.Z`. Add the
  release's changelog bullets under `## Unreleased` before bumping.
- `mise run git-push` pushes the branch together with tags.

## Commits

Conventional Commits. The scope is the script basename without `.sh`
(`fix(manage-audio): ...`, `refactor(rp-pruner): ...`), or `install`/`.github` for repo
infrastructure.

## Config ownership

Shared config is sourced from the `git-repo-scaffold` skill's `templates/common/`; pull updates
from there when the template changes rather than hand-tuning the common files.
