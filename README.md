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

The repo mirrors your home directory structure so symlinks remain simple.

```
~/Code/dotfiles/
├── .config/
│   └── ...
└── scripts/
    └── adopt-config
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

## Notes

- Do not edit files inside `~/.local/share/omarchy/` (those are managed by Omarchy updates).
- Use `git status` and `git commit` to version your changes when you’re ready.
