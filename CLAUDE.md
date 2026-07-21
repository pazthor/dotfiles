# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo tracks personal config file overrides for an [Omarchy](https://omarchy.org)-based Linux desktop. Only files you personally modify live here — Omarchy-managed files stay in `~/.local/share/omarchy/` and must not be edited directly.

The repo mirrors the home directory structure: `~/Code/dotfiles/config/.config/hypr/foo.conf` → `~/.config/hypr/foo.conf`.

## Key Scripts

Scripts live under `scripts/<context>/<script>` (e.g. `scripts/config/drift`),
grouped into contexts: `config/`, `git/`, `install/`, `media/`, `system/`. The
`dot` command (`bin/dot`, self-discovers its repo root via `BASH_SOURCE` and
is put on `$PATH` by `config/.bashrc`) runs any of them from anywhere:
`dot config drift`, `dot config adopt <path>`, etc. A bare script name also
works without the context prefix as long as it's unambiguous across contexts
— `dot drift`, `dot bootstrap --dry-run`. Running `dot` with no arguments
opens an fzf picker over every script; `dot <context>` scopes the picker to
one context.

| Script | Purpose |
|---|---|
| `scripts/config/adopt <path>` | Import an existing file: copies it into repo, replaces original with symlink, stages it |
| `scripts/config/unadopt <path>` | Remove a symlinked file from the repo, restoring it as a plain file in `$HOME` |
| `scripts/config/adopt-verify [path]` | Print canonical `config/… → $HOME/…` path mappings (no changes) |
| `scripts/config/link-config <path>` | Link a single already-tracked repo file back to its home location |
| `scripts/config/bootstrap [--dry-run\|--force]` | Link **every** tracked `config/` file into `$HOME` (idempotent) |
| `scripts/config/drift [--quiet]` | Report unadopted files, broken links, and leftover `.bak.*` in managed dirs (respects `.driftignore`) |
| `scripts/config/status` | Quick `git status` for the repo |
| `scripts/config/help` | Print tutorial + README |

### adopt-config behavior

- Refuses to adopt paths outside `$HOME`, already-symlinked files, or files already in the repo
- Creates a timestamped backup (`<original>.bak.<timestamp>`) before replacing with symlink
- Stages the new file with `git add` automatically

## Linking model

There is **one** mechanism: absolute symlinks from `$HOME` into `config/`, created
by the scripts above. GNU Stow and chezmoi are **not** used — do not reintroduce
them. `config/` is the single tree and mirrors the home layout under
`config/.config/...`, `config/.local/...`, `config/bin/...`, etc.

- Adopt a new file: `scripts/config/adopt ~/.config/hypr/foo.conf`
- Remove a file from the repo: `scripts/config/unadopt ~/.config/hypr/foo.conf`
- Re-link one existing tracked file: `scripts/config/link-config ~/.config/hypr/foo.conf`
- Re-link everything (new machine or after a pull): `scripts/config/bootstrap`

## Just recipes

```bash
just bootstrap          # link every tracked config into $HOME (idempotent)
just sync               # same as bootstrap; run after git pull
just update             # git pull --rebase, then re-link new/missing configs
just adopt ~/.config/hypr/bindings.conf   # adopt a single file
just verify ~/.config/hypr/bindings.conf  # preview path mapping without changes
```

Run `just` with no arguments to see all recipes.

## Validation

Run these to check changes are correct before committing:

```bash
bash -n scripts/*/*              # syntax-check all shell scripts
just --list                      # confirm Justfile parses cleanly
./scripts/config/bootstrap --dry-run   # preview what bootstrap would link
./scripts/config/drift                 # detect unadopted files or broken symlinks
```

## Machine-specific monitor overrides

`scripts/config/bootstrap` has special logic for monitor config: it symlinks
`~/.config/hypr/monitors-local.conf` to a machine-specific file selected by hostname:

- `config/.config/hypr/monitors-local.<hostname>.conf` — used if present
- `config/.config/hypr/monitors-local.default.conf` — fallback

To add a monitor layout for a new machine, copy `monitors-local.default.conf` to
`monitors-local.<hostname>.conf` and edit it (no adoption needed — it lives in the repo already).

## Environment variables

`.env.default` is a template for variables consumed by some configs (e.g. Neovim SSH log filtering). Copy it and fill in values:

```bash
cp .env.default ~/.env.dotfiles
# then source it from ~/.bashrc
```

## Bootstrapping on a new machine

```bash
git clone <repo> ~/Code/dotfiles
~/Code/dotfiles/scripts/config/bootstrap
```

## What NOT to edit

- `~/.local/share/omarchy/` — managed by Omarchy updates, changes will be overwritten
- Files not yet adopted — edit first, then adopt with `dot config adopt`

## Session completion

Work is not done until `git push` succeeds. Always push committed changes:

```bash
git pull --rebase && git push
```
