# Scripts

Helper scripts for miscellaneous purposes.

## Installation

Run the installer to symlink every script from `bin/` into `~/.local/bin`:

```sh
./install.sh
```

## Scripts

- `ftenv` — run a command with environment variables loaded from secret files.
- `manage-audio.sh` — select PulseAudio ports for a headset, speakers, or the internal mic.
- `move-to-next-monitor.sh` — move the active window to the next monitor (X11, single X screen).
- `notify-send-as-user.sh` — send a desktop notification as the session user, even when run with
  `sudo`.
- `rp-pruner.sh` — prune paths from restic snapshots through resticprofile.

## Development

Tooling and hooks are managed by [mise](https://mise.jdx.dev) and
[prek](https://github.com/j178/prek):

```sh
mise install
mise run lint
mise run test
```

## License

[MIT](LICENSE).
