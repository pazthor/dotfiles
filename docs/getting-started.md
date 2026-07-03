# Getting Started

This guide covers installing the dotfiles on a new machine and daily usage via
`just` recipes and scripts.

The repo uses **one** mechanism: absolute symlinks from `$HOME` into `config/`.
There is no Stow or chezmoi step.

---

## Install on a new machine

### 1. Install dependencies

```bash
# Arch Linux
sudo pacman -S git just

# Debian/Ubuntu
sudo apt install git
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
```

`just` is optional — every recipe is a thin wrapper over a script in `scripts/`.

### 2. Clone the repo

```bash
git clone git@github.com:pazthor/dotfiles.git ~/Code/dotfiles
cd ~/Code/dotfiles
```

### 3. Link everything into `$HOME`

```bash
just bootstrap
# or, without just:
scripts/bootstrap
```

This walks every file under `config/` and symlinks it into your home directory.
It is idempotent, so it is safe to re-run. Preview first with
`scripts/bootstrap --dry-run`; use `--force` to overwrite differing home files.

That's it — your config files are now linked.

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
| `just bootstrap [--force]` | Link or refresh repo-backed symlinks in `$HOME` |
| `just sync [--force]` | Alias for `just bootstrap`; useful after `git pull` |
| `just update` | `git pull --rebase`, then re-link new/missing configs |
| `just adopt <path>` | Adopt a file into the repo |
| `just verify [path]` | Preview path mapping |
| `just ydv` | Download a video from a copied URL |

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

### Link one file / link everything

```bash
scripts/link-config ~/.config/hypr/bindings.conf  # re-link a single tracked file
scripts/bootstrap                                 # re-link every tracked file
```

### Repo status

```bash
scripts/status   # git status for this repo
scripts/help     # print the full tutorial
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
Adopt it first with `scripts/adopt-config <path>`, then commit.
