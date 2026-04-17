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

## Layout

chezmoi source files live under `config/`, and helper scripts live under `scripts/`.

```
~/Code/dotfiles/
├── config/
│   ├── .config/
│   ├── bin/
│   └── commands/
└── scripts/
    ├── adopt-config
    └── chezmoi-sync
```

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
- Copy the file into the repo
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

Adopt a file with a shorter command:

```bash
~/Code/dotfiles/scripts/adopt ~/.config/hypr/bindings.conf
```

Check repo status quickly:

```bash
~/Code/dotfiles/scripts/status
```

Sync dotfiles with chezmoi (diff + apply):

```bash
~/Code/dotfiles/scripts/chezmoi-sync
```

## Using chezmoi with this repository

Daily management now uses chezmoi with the repo's real source layout at `~/Code/dotfiles/config`.

### 1. Install chezmoi

Examples:

```bash
# Arch
sudo pacman -S chezmoi

# Debian/Ubuntu
sudo apt install chezmoi
```

### 2. Initialize chezmoi to this source tree

After cloning this repo on a machine:

```bash
chezmoi init --source ~/Code/dotfiles/config
```

### 3. Apply current configuration

```bash
~/Code/dotfiles/scripts/chezmoi-sync
```

This wrapper runs:

- `chezmoi --source ~/Code/dotfiles/config diff`
- `chezmoi --source ~/Code/dotfiles/config apply`

### 4. Import an existing file and keep symlink targets

```bash
chezmoi --source ~/Code/dotfiles/config add --follow ~/.config/hypr/hyprsunset.conf
```

### 5. Work inside the managed source directory

```bash
chezmoi --source ~/Code/dotfiles/config cd
```

Repository modules managed by chezmoi:

```text
~/Code/dotfiles/config/
├── .config/
├── bin/
└── commands/
```

See `docs/chezmoi.md` for migration steps and operational details.

## Notes

- Do not edit files inside `~/.local/share/omarchy/` (those are managed by Omarchy updates).
- Use `git status` and `git commit` to version your changes when you’re ready.
