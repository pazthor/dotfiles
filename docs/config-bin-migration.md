# `config/bin` migration notes

`config/bin/` used to contain symlinks pointing at `config/commands/*`.
The canonical source for user-facing executables is now:

- `config/.local/bin/`

This matches the target runtime location `~/.local/bin/` in chezmoi-managed homes.

## Path-by-path migration map

| Previous path (`config/bin/*`) | New canonical file | Notes for `chezmoi apply` |
| --- | --- | --- |
| `config/bin/format-flash` | `config/.local/bin/format-flash` | Install as a real executable file in `~/.local/bin/format-flash`. |
| `config/bin/mount-flash` | `config/.local/bin/mount-flash` | Install as a real executable file in `~/.local/bin/mount-flash`. |
| `config/bin/toggle-laptop-display` | `config/.local/bin/toggle-laptop-display` | Install as a real executable file in `~/.local/bin/toggle-laptop-display`. |
| `config/bin/update-from-staging` | `config/.local/bin/update-from-staging` | Install as a real executable file in `~/.local/bin/update-from-staging`. |
| `config/bin/whatsapp-video` | `config/.local/bin/whatsapp-video` | Install as a real executable file in `~/.local/bin/whatsapp-video`. |
| `config/bin/yda` | `config/.local/bin/yda` | Install as a real executable file in `~/.local/bin/yda`. |
| `config/bin/ydp` | `config/.local/bin/ydp` | Install as a real executable file in `~/.local/bin/ydp`. |

## Why this migration

- Removes intra-repo symlink hops.
- Keeps executables in one stable source location.
- Makes first `chezmoi apply` deterministic (files are materialized directly, not linked indirectly).
