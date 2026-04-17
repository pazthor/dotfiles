# Migrating from GNU Stow to chezmoi

This repository now uses [chezmoi](https://www.chezmoi.io/) for day-to-day dotfile management.

- Repo root: `~/Code/dotfiles`
- chezmoi source directory in this repo: `~/Code/dotfiles/config`
- Managed layout under source: `.config/`, `bin/`, and `commands/`

Use this guide to migrate existing Stow usage and run daily operations.

## 1. Initialize chezmoi with this repository

If this is a new machine, clone the repo and initialize chezmoi to use the `config/` source tree:

```bash
git clone <your-remote> ~/Code/dotfiles
chezmoi init --source ~/Code/dotfiles/config
```

This points chezmoi at the repo's actual module layout:

```text
~/Code/dotfiles/config/
├── .config/
├── bin/
└── commands/
```

## 2. Preview and apply changes

For regular syncs, run:

```bash
~/Code/dotfiles/scripts/chezmoi-sync
```

The wrapper runs:

1. `chezmoi --source ~/Code/dotfiles/config diff`
2. `chezmoi --source ~/Code/dotfiles/config apply`

You can pass apply flags through the wrapper, for example:

```bash
~/Code/dotfiles/scripts/chezmoi-sync --dry-run
~/Code/dotfiles/scripts/chezmoi-sync --verbose
```

## 3. Add existing files into chezmoi management

If a file exists in `$HOME` and is not managed yet, add it with follow mode:

```bash
chezmoi --source ~/Code/dotfiles/config add --follow ~/.config/hypr/hyprsunset.conf
```

`--follow` captures the target content if the file is currently a symlink.

## 4. Edit files directly in the source directory

Open the source tree in place:

```bash
chezmoi --source ~/Code/dotfiles/config cd
```

Then edit files under:

- `~/.config/...` equivalents in `~/Code/dotfiles/config/.config/...`
- `~/bin/...` equivalents in `~/Code/dotfiles/config/bin/...`
- custom command scripts in `~/Code/dotfiles/config/commands/...`

After editing, apply updates:

```bash
~/Code/dotfiles/scripts/chezmoi-sync
```

## 5. Migration checklist from old Stow workflows

- Stop using `scripts/stow-pack` and direct `stow ...` commands.
- Use `chezmoi init --source ~/Code/dotfiles/config` once per machine.
- Use `chezmoi add --follow <path>` when importing existing files.
- Use `chezmoi cd` + normal edits for ongoing changes.
- Use `chezmoi apply` (or `scripts/chezmoi-sync`) to deploy changes.
