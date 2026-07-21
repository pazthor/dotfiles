# Getting Started

This guide covers installing the dotfiles on a new machine and daily usage via
`dot` commands and `just` recipes.

The repo uses **one** mechanism: absolute symlinks from `$HOME` into `config/`.
There is no Stow or chezmoi step.

---

## Install on a new machine

### 1. Install dependencies

```bash
# Arch Linux
sudo pacman -S git just fzf

# Debian/Ubuntu
sudo apt install git fzf
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
```

`just` is optional — every recipe is a thin wrapper over a script in `scripts/`.
`fzf` is needed for the interactive `dot` picker.

### 2. Clone the repo

```bash
git clone git@github.com:pazthor/dotfiles.git ~/Code/dotfiles
cd ~/Code/dotfiles
```

### 3. Install dot and link configs

```bash
just install-dot
# or, without just:
scripts/install/dot
```

This will:
- Symlink every file under `config/` into your home directory (idempotent)

### 4. Activate in your current shell

```bash
source ~/.bashrc
```

That's it — `dot` is now available.

```bash
dot                  # FZF picker over all scripts
dot config           # pick a config script
dot config drift     # check for unadopted files
```

For the pi coding agent (install, auth, skills), see [pi-setup.md](pi-setup.md).

---

## Daily usage with `dot`

`dot` is the main script dispatcher. All scripts in `scripts/<context>/<name>` are
reachable as `dot <context> <name>`.

```bash
dot                                          # FZF picker: all scripts
dot config                                   # FZF picker: config context only
dot config adopt ~/.config/hypr/bindings.conf
dot config adopt-verify
dot config drift
dot config bootstrap
dot config status
dot git glab-mr
dot install inshellisense
dot system build-split-monitor-workspaces
```

Use `-h` on any script for help:

```bash
dot config adopt -h
dot config drift -h
```

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
# or:
dot config adopt ~/.config/hypr/bindings.conf
```

This copies the file into the repo under `config/`, replaces the original with a
symlink, and stages it with git.

### Preview a file's repo mapping

```bash
just verify ~/.config/hypr/bindings.conf
just verify                                  # show all mappings
```

### Refresh after pulling changes

Existing symlinks pick up repo edits immediately. After a `git pull` that adds
new tracked files, re-link them:

```bash
git pull
just sync        # links newly added files and repairs missing links
```

`just update` combines both steps (`git pull --rebase`, then re-link).

### Full recipe list

| Recipe | What it does |
|---|---|
| `just install-dot` | Bootstrap the repo and print activation instructions (run once on new machines) |
| `just bootstrap [--force]` | Link or refresh repo-backed symlinks in `$HOME` |
| `just sync [--force]` | Alias for `just bootstrap`; useful after `git pull` |
| `just update` | `git pull --rebase`, then re-link new/missing configs |
| `just adopt <path>` | Adopt a file into the repo |
| `just verify [path]` | Preview path mapping |
| `just ydv` | Download a video from a copied URL |

---

## Daily usage with scripts

All scripts live under `scripts/<context>/<name>` and are executable, so they
can also be called directly by path instead of through `dot`:

### Adopt a file

```bash
scripts/config/adopt ~/.config/hypr/bindings.conf
```

### Verify mappings

```bash
scripts/config/adopt-verify                              # print all mappings
scripts/config/adopt-verify ~/.config/hypr/bindings.conf # check one path
```

### Link one file / link everything

```bash
scripts/config/link-config ~/.config/hypr/bindings.conf  # re-link a single tracked file
scripts/config/bootstrap                                 # re-link every tracked file
```

### Repo status

```bash
scripts/config/status   # git status for this repo
scripts/config/help     # print the full tutorial
```

---

## Troubleshooting

**`bootstrap` reports `skipped` files**
Files already correctly symlinked are skipped — that is expected. `failed`
counts are the ones to investigate.

**A home file differs from the repo version**
`bootstrap`/`link-config` refuse to clobber it by default. Inspect the
difference, then re-run with `--force` once you're sure the repo copy should win.

**A config file I edited isn't tracked yet**
Adopt it first with `dot config adopt <path>`, then commit.

**`dot` command not found after bootstrap**
Run `source ~/.bashrc`. `DOTFILES_PATH` is set there and `$DOTFILES_PATH/bin`
(which contains `dot`) is prepended to `PATH`.
