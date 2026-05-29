# Getting Started

This guide covers installing the dotfiles on a new machine and daily usage via `just` recipes and scripts.

---

## Install on a new machine

### 1. Install dependencies

```bash
# Arch Linux
sudo pacman -S git chezmoi just stow

# Debian/Ubuntu
sudo apt install git stow
sh -c "$(curl -fsLS get.chezmoi.io)"         # install chezmoi
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
```

### 2. Clone the repo

```bash
git clone git@github.com:pazthor/dotfiles.git ~/Code/dotfiles
cd ~/Code/dotfiles
```

### 3. Import all config files into chezmoi

```bash
just import
```

This discovers every file tracked in the repo and registers it with chezmoi. Files not yet present on disk are skipped with a warning — that is normal.

### 4. Preview and apply

```bash
just review   # see what chezmoi will change
just apply    # apply changes to your home directory
```

That's it. Your config files are now managed by chezmoi.

For the pi coding agent (install, auth, skills), see [pi-setup.md](pi-setup.md).

---

## Daily usage with `just`

Run `just` with no arguments to list all available recipes:

```
just
```

### Adopt a new config file

When you edit a config file and want to start tracking it:

```bash
just adopt ~/.config/hypr/bindings.conf
```

This copies the file into the repo under `config/` and replaces the original with a symlink.

### Preview a file's repo mapping

```bash
just verify ~/.config/hypr/bindings.conf
just verify                                  # show all mappings
```

### Review and apply pending changes

```bash
just review   # chezmoi diff — shows what would change
just apply    # apply changes (prompts for confirmation)
```

### Refresh after pulling changes

If your home directory uses repo-backed symlinks, refresh links after `git pull`:

```bash
git pull
just sync
```

Existing symlinks pick up repo edits immediately; `just sync` mainly links newly added files and repairs missing links.

If you manage materialized files with chezmoi instead of symlinks, run `just apply` after pulling:

```bash
git pull
just apply
```

### Full recipe list

| Recipe | What it does |
|---|---|
| `just bootstrap [--force]` | Link or refresh repo-backed symlinks in `$HOME` |
| `just sync [--force]` | Alias for `just bootstrap`; useful after `git pull` |
| `just import` | Import all repo files into chezmoi |
| `just review` | Preview pending chezmoi changes |
| `just apply` | Apply chezmoi changes interactively |
| `just adopt <path>` | Adopt a file into the repo |
| `just verify [path]` | Preview path mapping |
| `just migrate` | Dry-run stow→chezmoi migration |
| `just migrate-inventory` | List files not yet in chezmoi |
| `just migrate-import` | Import via make target |
| `just migrate-diff` | `chezmoi diff` via make |
| `just migrate-apply` | `chezmoi apply` via make |
| `just migrate-verify` | Verify symlinks via make |

---

## Daily usage with scripts

All scripts live in `scripts/` and can be called directly.

### Adopt a file

```bash
scripts/adopt-config ~/.config/hypr/bindings.conf
# or the short alias:
scripts/adopt ~/.config/hypr/bindings.conf
```

### Verify mappings

```bash
scripts/adopt-verify                              # print all mappings
scripts/adopt-verify ~/.config/hypr/bindings.conf # check one path
```

### chezmoi wrapper

```bash
scripts/chezmoi inventory         # list files not yet managed by chezmoi
scripts/chezmoi add-follow <path> # safely add a file to chezmoi
scripts/chezmoi review            # chezmoi diff
scripts/chezmoi apply             # chezmoi apply (prompts)
scripts/chezmoi apply --yes       # apply without prompting
```

### Migration script

```bash
scripts/migrate-stow-to-chezmoi --dry-run   # preview what would be imported
scripts/migrate-stow-to-chezmoi --import    # run the full import
```

### Repo status

```bash
scripts/status   # git status for this repo
scripts/help     # print the full tutorial
```

---

## Troubleshooting

**`just import` shows warnings about missing targets**
Files in the repo that aren't linked on this machine are skipped. This is expected — run `just sync` to create the missing symlinks first, then re-run `just import`.

**`chezmoi apply` overwrites a file I didn't expect**
Run `just review` before applying to see exactly what will change. If a file is managed by chezmoi but shouldn't be, remove it with `chezmoi forget <path>`.

**A config file I edited isn't tracked yet**
Run `just adopt ~/.config/path/to/file` to add it to the repo.
