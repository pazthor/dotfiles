# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo tracks personal config file overrides for an [Omarchy](https://omarchy.org)-based Linux desktop. Only files you personally modify live here — Omarchy-managed files stay in `~/.local/share/omarchy/` and must not be edited directly.

The repo mirrors the home directory structure so symlinks are straightforward: `~/Code/dotfiles/.config/hypr/foo.conf` → `~/.config/hypr/foo.conf`.

## Key Scripts

All scripts live in `scripts/` and are executable. The `dot` command
(`config/.local/bin/dot`, symlinked to `~/.local/bin/dot` by bootstrap) runs any
of them from anywhere: `dot drift`, `dot adopt-config <path>`, etc. Running
`dot` with no arguments lists all subcommands.

| Script | Purpose |
|---|---|
| `scripts/adopt-config <path>` | Import an existing file: copies it into repo, replaces original with symlink, stages it |
| `scripts/unadopt-config <path>` | Remove a symlinked file from the repo, restoring it as a plain file in `$HOME` |
| `scripts/adopt <path>` | Alias for `adopt-config` |
| `scripts/adopt-verify [path]` | Print canonical `config/… → $HOME/…` path mappings (no changes) |
| `scripts/link-config <path>` | Link a single already-tracked repo file back to its home location |
| `scripts/bootstrap [--dry-run\|--force]` | Link **every** tracked `config/` file into `$HOME` (idempotent) |
| `scripts/drift [--quiet]` | Report unadopted files, broken links, and leftover `.bak.*` in managed dirs (respects `.driftignore`) |
| `scripts/status` | Quick `git status` for the repo |
| `scripts/help` | Print tutorial + README |

### adopt-config behavior

- Refuses to adopt paths outside `$HOME`, already-symlinked files, or files already in the repo
- Creates a timestamped backup (`<original>.bak.<timestamp>`) before replacing with symlink
- Stages the new file with `git add` automatically

## Linking model

There is **one** mechanism: absolute symlinks from `$HOME` into `config/`, created
by the scripts above. GNU Stow and chezmoi are **not** used — do not reintroduce
them. `config/` is the single tree and mirrors the home layout under
`config/.config/...`, `config/.local/...`, `config/bin/...`, etc.

- Adopt a new file: `scripts/adopt-config ~/.config/hypr/foo.conf`
- Remove a file from the repo: `scripts/unadopt-config ~/.config/hypr/foo.conf`
- Re-link one existing tracked file: `scripts/link-config ~/.config/hypr/foo.conf`
- Re-link everything (new machine or after a pull): `scripts/bootstrap`

## Bootstrapping on a New Machine

```bash
git clone <repo> ~/Code/dotfiles
~/Code/dotfiles/scripts/bootstrap
```

## makefile / Justfile

No build system is used; scripts are plain bash. The `makefile` and `Justfile`
are thin wrappers over `scripts/` (`bootstrap`, `adopt-config`, `adopt-verify`).
`make adot-config` is a deprecated alias that forwards to `adopt-config`.

## What NOT to edit

- `~/.local/share/omarchy/` — managed by Omarchy updates, changes will be overwritten
- Files not yet adopted — edit first, then adopt with `adopt-config`
