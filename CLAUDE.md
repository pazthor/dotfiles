# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo tracks personal config file overrides for an [Omarchy](https://omarchy.org)-based Linux desktop. Only files you personally modify live here — Omarchy-managed files stay in `~/.local/share/omarchy/` and must not be edited directly.

The repo mirrors the home directory structure so symlinks are straightforward: `~/Code/dotfiles/.config/hypr/foo.conf` → `~/.config/hypr/foo.conf`.

## Key Scripts

All scripts live in `scripts/` and are executable:

| Script | Purpose |
|---|---|
| `scripts/adopt-config <path>` | Import an existing file: copies it into repo, replaces original with symlink, stages it |
| `scripts/adopt <path>` | Alias for `adopt-config` |
| `scripts/stow-pack [stow-opts] <pkg>` | Wrapper around GNU Stow with `--dir ~/Code/dotfiles --target ~` preset |
| `scripts/status` | Quick `git status` for the repo |
| `scripts/help` | Print tutorial + README |

### adopt-config behavior

- Refuses to adopt paths outside `$HOME`, already-symlinked files, or files already in the repo
- Creates a timestamped backup (`<original>.bak.<timestamp>`) before replacing with symlink
- Stages the new file with `git add` automatically

### stow-pack behavior

- Expects GNU Stow package directories at repo root (e.g., `hypr/`, `waybar/`)
- Each package dir mirrors the home layout: `hypr/.config/hypr/...`
- Use `--restow` to refresh links, `--delete` to remove links

## Adopt-then-Stow Workflow

1. Adopt a file with `adopt-config` (creates symlink in place)
2. Move the adopted file into a Stow package dir: `mv config/.config/hypr/foo.conf hypr/.config/hypr/foo.conf`
3. Remove the old direct symlink and re-link via Stow: `stow-pack hypr`

Once in a Stow package, use `stow-pack --restow <pkg>` for day-to-day link management.

The current active Stow package is `config/`, which holds all adopted config files. Its structure mirrors the home directory under `config/.config/...`.

## Bootstrapping on a New Machine

```bash
git clone <repo> ~/Code/dotfiles
~/Code/dotfiles/scripts/stow-pack hypr
# repeat for each package
```

## makefile

The makefile currently has a broken `adot-config` target (typo — tracked as a known issue). No build system is used; scripts are plain bash.

## What NOT to edit

- `~/.local/share/omarchy/` — managed by Omarchy updates, changes will be overwritten
- Files not yet adopted — edit first, then adopt with `adopt-config`
