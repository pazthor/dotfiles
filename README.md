# Dotfiles (Omarchy Overrides)

This repo tracks only the config files you personally modify. It keeps all changes in user override locations so Omarchy updates do not overwrite them.

## Quick start

1. Edit any config file you want to customize.
2. Adopt it into this repo with the helper script:

```bash
~/Code/dotfiles/scripts/config/adopt ~/.config/hypr/bindings.conf
```

The script will:
- Copy the file into this repo
- Replace the original with a symlink
- Stage the file with git

Before importing, you can preview canonical mappings:

```bash
~/Code/dotfiles/scripts/config/adopt-verify
~/Code/dotfiles/scripts/config/adopt-verify ~/.config/hypr/bindings.conf
```

## The `dot` command

After bootstrapping, `dot` is on PATH (`bin/dot`, self-discovers its repo
root and is prepended to `$PATH` by `config/.bashrc`) and runs any script
under `scripts/<context>/` from anywhere:

```bash
dot config adopt ~/.config/hypr/bindings.conf
dot config adopt-verify
dot config drift
dot config bootstrap
dot            # fzf picker over all scripts
dot config     # fzf picker scoped to the config context
```

The context prefix can be dropped when the script name is unambiguous:
`dot drift`, `dot bootstrap --dry-run`, `dot adopt-verify` all work too.

## Quick commands (just)

If you have [just](https://github.com/casey/just) installed, these recipes wrap the common workflows:

```bash
just bootstrap          # link every tracked config into $HOME (idempotent)
just sync               # same as bootstrap; run after `git pull`
just update             # git pull --rebase, then re-link new/missing configs
just adopt ~/.config/hypr/bindings.conf  # adopt a single file into the repo
just verify ~/.config/hypr/bindings.conf # preview a path mapping
```

Run `just` with no arguments to see all available recipes.

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
~/Code/dotfiles/scripts/config/adopt ~/.config/hypr/bindings.conf
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
~/Code/dotfiles/scripts/config/help
```

Print canonical mapping samples and preview a specific path:

```bash
~/Code/dotfiles/scripts/config/adopt-verify
~/Code/dotfiles/scripts/config/adopt-verify ~/bin/my-helper
```

Check repo status quickly:

```bash
~/Code/dotfiles/scripts/config/status
```

## Re-linking everything (`scripts/config/bootstrap`)

`scripts/config/adopt` imports one file at a time. To (re)create every symlink
in one pass — after cloning on a new machine, or after `git pull` adds new
tracked files — use `scripts/config/bootstrap`. It walks every file under
`config/` and links it into `$HOME` via `scripts/config/link-config`. It is
idempotent, so it is safe to re-run.

```bash
~/Code/dotfiles/scripts/config/bootstrap --dry-run   # preview what would be linked
~/Code/dotfiles/scripts/config/bootstrap             # link everything
~/Code/dotfiles/scripts/config/bootstrap --force     # overwrite differing home files
```

Equivalent `just` recipes: `just bootstrap`, `just sync` (after a pull), and
`just update` (pull + re-link).

## Bootstrap on a new machine

```bash
git clone <repo> ~/Code/dotfiles
~/Code/dotfiles/scripts/config/bootstrap
```

That single command links every tracked config into place — there are no
separate packages to install.

## Notes

- Do not edit files inside `~/.local/share/omarchy/` (those are managed by Omarchy updates).
- Use `git status` and `git commit` to version your changes when you’re ready.
