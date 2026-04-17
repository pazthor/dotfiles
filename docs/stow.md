# Managing Dotfiles with GNU Stow

This repository mirrors the layout of files once they are linked into `$HOME`. GNU Stow keeps the tree tidy by creating symlinks instead of copying files. The walkthrough below shows the standard workflow for applying and maintaining this configuration.

## Prerequisites

- Ensure GNU Stow is installed (`sudo apt install stow`, `brew install stow`, etc.).
- Run all commands from the repository root (the directory containing `home/`, `config/`, `bin/`, and any `hosts/<hostname>/` overrides).

## Apply Core Modules

```sh
stow --target="$HOME" home config bin
```

- Links the shared shell, editor, and helper scripts into your home directory.
- Run this command whenever new files are added under those modules.

## Dry Runs During Review

```sh
stow --no --target="$HOME" home config bin
```

- Adds the `--no` flag to preview what would be linked without touching the filesystem.
- Useful for verifying changes or reviewing a pull request locally.

## Host-Specific Overlays

```sh
stow --target="$HOME" hosts/"$(hostname)"
```

- Applies machine-specific tweaks from `hosts/<hostname>/`.
- Create a new host directory when a machine needs overrides that shouldn't be shared globally.

## Linking Individual Modules

You can scope Stow to a single module when experimenting or rolling out new files:

```sh
stow --target="$HOME" config/nvim
stow --target="$HOME" bin
```

- Each subdirectory under `home/`, `config/`, or `bin/` can be managed independently.
- Mix and match modules to suit a minimal setup on remote hosts or servers.

## Removing Symlinks Cleanly

```sh
stow --delete --target="$HOME" config/nvim
```

- Removes symlinks created by the matching `stow` command without touching the source files in the repo.
- Use this when deprecating a module or rolling back a change.

## Adding an Existing Config File to the Repo

When a config file already exists on the system (e.g., `~/.config/hypr/looknfeel.conf`) and you want to start tracking it in this dotfiles repo:

1. **Copy or move** the file into the repo under its mirrored path:
   ```sh
   cp ~/.config/hypr/looknfeel.conf .config/hypr/looknfeel.conf
   ```
   Or let `make stow-adopt` do it automatically (see step 3).

2. **Verify** the repo path mirrors `$HOME` (e.g., `.config/hypr/` → `~/.config/hypr/`).

3. **Adopt and link** in one step — stow will move the real file into the repo and replace it with a symlink:
   ```sh
   make stow-adopt
   # Equivalent: stow --verbose --adopt --no-folding . --target=$HOME
   ```

4. **Commit** the new file:
   ```sh
   git add .config/hypr/looknfeel.conf
   git commit -m "feat(hypr): track looknfeel overrides"
   ```

5. **Verify** the symlink:
   ```sh
   ls -la ~/.config/hypr/looknfeel.conf
   # Expected: ... -> ../../Code/dotfiles-omarchy/.config/hypr/looknfeel.conf
   ```

> **Note:** `--adopt` can overwrite repo files with whatever is on disk. Only use it when the on-disk version is the one you want to keep, or when the repo file is identical.

## Maintenance Tips

- After editing package manifests or bootstrap scripts, run `scripts/bootstrap --dry-run` and then re-run the relevant `stow` command.
- Keep secrets or machine-local files untracked; add `.example` templates if setup requires manual values.
- Run `stow` again after pulling updates to ensure new files are linked.
