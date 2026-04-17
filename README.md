# Dotfiles (Omarchy Overrides)

This repo tracks only the config files you personally modify. It keeps all changes in user override locations so Omarchy updates do not overwrite them.

## Quick start

1. Edit any config file you want to customize.
2. Adopt it into this repo with the helper script:

```bash
~/Code/dotfiles/scripts/adopt-config ~/.config/hypr/bindings.conf
```

The script will:
- Copy the file into this repo
- Replace the original with a symlink
- Stage the file with git

Before importing, you can preview canonical mappings:

```bash
~/Code/dotfiles/scripts/adopt-verify
~/Code/dotfiles/scripts/adopt-verify ~/.config/hypr/bindings.conf
```

## Layout

The repo uses a canonical package root model:

- `config/` maps to `$HOME`
- `scripts/` is **repo tooling**, not a package to install into `$HOME`

```
~/Code/dotfiles/
├── config/
│   ├── .config/
│   │   └── ...
│   └── bin/
│       └── ...
└── scripts/
    ├── adopt-config
    └── adopt-verify
```

Examples:

- `config/.config/hypr/hyprland.conf` → `~/.config/hypr/hyprland.conf`
- `config/bin/my-script` → `~/bin/my-script`

## Tutorial

### 1. Pick a file to customize

Edit the real config file first, for example:

```bash
$EDITOR ~/.config/hypr/bindings.conf
```

### 2. Adopt the file into the repo

```bash
~/Code/dotfiles/scripts/adopt-config ~/.config/hypr/bindings.conf
```

This will:
- Copy the file into `config/...` in the repo
- Replace the original with a symlink
- Stage it with git
- Keep a timestamped backup next to the original

### 3. Commit your change

```bash
git -C ~/Code/dotfiles status
git -C ~/Code/dotfiles commit -m "Add custom hypr bindings"
```

### 4. Edit later

When you edit the file again, you can edit the symlink target directly:

```bash
$EDITOR ~/.config/hypr/bindings.conf
```

### 5. Restore a backup (if needed)

If you need to revert to the pre-adopt file:

```bash
ls ~/.config/hypr/bindings.conf.bak.*
rm ~/.config/hypr/bindings.conf
mv ~/.config/hypr/bindings.conf.bak.<timestamp> ~/.config/hypr/bindings.conf
```

## Helper Command

Print the quick summary plus full tutorial:

```bash
~/Code/dotfiles/scripts/help
```

Print canonical mapping samples and preview a specific path:

```bash
~/Code/dotfiles/scripts/adopt-verify
~/Code/dotfiles/scripts/adopt-verify ~/bin/my-helper
```

Adopt a file with a shorter command:

```bash
~/Code/dotfiles/scripts/adopt ~/.config/hypr/bindings.conf
```

Check repo status quickly:

```bash
~/Code/dotfiles/scripts/status
```

Run stow with repo defaults (`--dir ~/Code/dotfiles --target ~`):

```bash
~/Code/dotfiles/scripts/stow-pack --restow hypr
```


## Migration lifecycle (chezmoi)

Use the explicit lifecycle commands in `makefile` when migrating tracked config into chezmoi:

```bash
make migrate-inventory
make migrate-import
make migrate-diff
make migrate-apply
make migrate-verify
```

- `migrate-inventory`: generate `.cache/chezmoi-migration-manifest.txt` from tracked config paths.
- `migrate-import`: run `chezmoi add --follow` for each manifest entry.
- `migrate-diff`: preview pending changes.
- `migrate-apply`: enforce managed state.
- `migrate-verify`: report missing paths or paths that are no longer symlinks.

## Using GNU Stow with `scripts/adopt-config`

`scripts/adopt-config` and Stow work well together when you split responsibilities:

- `adopt-config`: import an existing local file into this repo without losing your current setup.
- `stow`: recreate all symlinks cleanly on the same machine later, or on a new machine after cloning.

### 1. Install Stow

Examples:

```bash
# Arch
sudo pacman -S stow

# Debian/Ubuntu
sudo apt install stow
```

### 2. Recommended Stow package layout

Create package directories at repo root (one package per tool/topic):

```text
~/Code/dotfiles/
├── hypr/
│   └── .config/hypr/...
├── waybar/
│   └── .config/waybar/...
└── scripts/
```

### 3. Adopt first, then move into a Stow package

Example for `~/.config/hypr/hyprsunset.conf`:

```bash
# 1) Adopt with your helper script
~/Code/dotfiles/scripts/adopt-config ~/.config/hypr/hyprsunset.conf

# 2) Move adopted file into a Stow package
mkdir -p ~/Code/dotfiles/hypr/.config/hypr
mv ~/Code/dotfiles/config/.config/hypr/hyprsunset.conf \
  ~/Code/dotfiles/hypr/.config/hypr/hyprsunset.conf

# 3) Replace old direct symlink with a Stow-managed symlink
rm ~/.config/hypr/hyprsunset.conf
stow --dir ~/Code/dotfiles --target ~ hypr
```

After this, the file is managed by Stow package `hypr`.

### 4. Daily workflow with Stow

```bash
# Re-apply package links after file moves/renames
~/Code/dotfiles/scripts/stow-pack --restow hypr

# Remove package links
~/Code/dotfiles/scripts/stow-pack --delete hypr
```

### 5. Bootstrap on a new machine

After cloning this repo:

```bash
~/Code/dotfiles/scripts/stow-pack hypr
# add more packages as you create them, for example:
# ~/Code/dotfiles/scripts/stow-pack waybar
```

Tip: avoid storing dotfiles directly in repo root once you start using Stow packages. Keep them under package folders (`hypr/`, `waybar/`, etc.) so `stow` can manage them consistently.

## Notes

- Do not edit files inside `~/.local/share/omarchy/` (those are managed by Omarchy updates).
- Use `git status` and `git commit` to version your changes when you’re ready.
