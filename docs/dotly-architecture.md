# Dotly Architecture — Staff Engineer Study Guide

## System Architecture

The setup composes two repos that stay independent but cooperate through two env vars:

```
DOTLY_PATH=$HOME/Code/dotly        # framework: the dot dispatcher + built-in scripts
DOTFILES_PATH=$HOME/Code/dotfiles  # personal: your configs + your scripts
```

`bin/dot` merges them at runtime: it searches `$DOTFILES_PATH/scripts` first, then
`$DOTLY_PATH/scripts`. Your scripts win over framework built-ins. Neither repo needs to
know where the other lives — the coupling is entirely in those two variables, set in
`.bashrc`.

```
dot config adopt   →  $DOTFILES_PATH/scripts/config/adopt   (yours)
dot git commit     →  $DOTLY_PATH/scripts/git/commit         (framework)
```

---

## Best Practices in Use

### 1. `set -euo pipefail` on every script

```bash
set -euo pipefail
```

- `-e`: exit on any command failure (no silent swallowing of errors)
- `-u`: unset variables are errors, not empty strings
- `-o pipefail`: a pipe fails if any stage fails, not just the last one

This is the baseline for production-quality bash. Without `-u`, `rm -rf "$DIR/"` on an
unset `$DIR` becomes `rm -rf /`.

### 2. Portable self-location via `BASH_SOURCE`

```bash
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
```

Scripts know where they are without needing env vars. The `cd && pwd` pattern resolves
symlinks and gives an absolute path. `--` after `dirname` prevents directory names
starting with `-` from being parsed as flags. This is the correct pattern — `$0` breaks
under `source`, `BASH_SOURCE[0]` doesn't.

### 3. Idempotency as a first-class design goal

Every state-changing script is safe to re-run:

- `bootstrap` → checks if already linked before linking
- `adopt` → refuses to overwrite an existing repo file
- `install/dot` → checks if `~/Code/dotly` is already cloned
- `link-config` → detects "already linked" as a distinct non-error case

This is the property that makes automation trustworthy. A script you can only run once
is a liability.

### 4. Semantic exit codes

`link-config` uses three exit codes with distinct meanings:

- `0` — success
- `1` — error
- `2` — skipped (file already linked)

`bootstrap` uses this to distinguish `failed` from `skipped` counts. This lets callers
react differently to each case without parsing stdout.

### 5. Stderr for diagnostics, stdout for data

```bash
echo "Error: unsupported path: $source_path" >&2
printf '%s\n' "${candidates[0]}"   # stdout: the actual result
```

Errors go to stderr (`>&2`). Usable output goes to stdout. This means you can pipe the
output of scripts safely: `dot config adopt-verify | grep config` won't include error
messages.

### 6. `readonly` on constants

```bash
readonly PACKAGE_ROOTS=(
  "config:$HOME"
)
```

Prevents accidental mutation later in the script. On constants that define the behavior
of the entire script (like package roots), this is important defensive practice.

### 7. Backup before destructive operations

```bash
timestamp=$(date +%Y%m%d%H%M%S)
backup_path="$source_path.bak.$timestamp"
mv -- "$source_path" "$backup_path"
```

`adopt` and `link-config` never delete a file — they back it up with a timestamp. The
`drift` script then surfaces these as `leftover:` entries. The chain is: backup →
operate → user reviews → user deletes. No data loss path.

### 8. `git -C <path>` instead of `cd`

```bash
git -C "$repo_root" add "$repo_path"
git -C "$repo_root" ls-files -- 'config/'
```

Never `cd` inside a script that other scripts might call. `-C` runs git in a specific
directory without changing the process's working directory. Composable, no side effects.

---

## Philosophy / Mental Models

### Convention over configuration

The `dot` dispatcher works because everyone agrees: scripts live at
`scripts/<context>/<name>`, they're executable files, nothing else. There's no registry,
no manifest, no config file. The filesystem *is* the configuration. You add a script and
it immediately appears in `dot` and the FZF picker.

The depth constraint (exactly 2 levels, `find -maxdepth 2`) is part of the convention.
Violate it and the script disappears silently. This is a trade-off: simple discovery in
exchange for a structural rule you must internalize.

### Locality — scripts own their own paths

No script depends on `DOTFILES_PATH` being set to find its siblings. `bootstrap` calls
`$script_dir/link-config`, not `$DOTFILES_PATH/scripts/config/link-config`. If you move
the whole repo, everything still works because scripts navigate relative to themselves.

### Composition over monolith

`bootstrap` doesn't implement linking — it calls `link-config` in a loop.
`adopt-verify` doesn't implement verification — it calls `adopt --verify`. Each script
has one job. You can call any piece independently. This is Unix philosophy: small tools
that compose.

### Idempotency enables automation

Any script you can safely re-run multiple times is a script you can put in CI, in an
installer, or call by accident. The install script, bootstrap, and adopt are all
idempotent. This property is what separates "scripts" from "automation."

---

## Where to Push Back

### 1. `yt-dlp` is not a script, it's a notes file

```bash
# scripts/media/yt-dlp — current content:
yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" -o "%(title)s.%(ext)s"
yt-dlp -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" --merge-output-format mp4 https://youtube.com/shorts/...
```

No shebang, references a hardcoded URL, multiple commands that can't all run. When
`dot media yt-dlp` executes this, bash will try to run all lines and fail on the second
one. Either make it a real script that takes a URL as an argument, or move it to `docs/`
as a cheatsheet.

### 2. `link-config` has an inconsistent path normalizer

`adopt` and `unadopt` use `readlink -f`:

```bash
normalize_path() {
  readlink -f -- "$raw"   # adopt, unadopt
}
```

`link-config` uses Python:

```bash
normalize_path() {
  python -c 'import os, sys; print(os.path.abspath(os.path.expanduser(sys.argv[1])))' "$raw"
}
```

`readlink -f` follows symlinks to the final target; `os.path.abspath` doesn't. The
inconsistency is a latent bug if a symlink is in the path. Fix `link-config` to use
`readlink -f` like its siblings.

### 3. `PACKAGE_ROOTS` is copy-pasted into three scripts

`adopt`, `link-config`, and `unadopt` each declare the same array:

```bash
readonly PACKAGE_ROOTS=(
  "config:$HOME"
)
```

If you ever add a second package root, you must update three files and it's easy to miss
one. The practical fix is a shared library file:

```bash
# scripts/config/_lib.sh  (not executable, not dispatched by dot)
PACKAGE_ROOTS=("config:$HOME")
```

Then source it in each script. The underscore prefix by convention marks it as a
non-dispatchable helper (dotly's `find -maxdepth 2 -perm /+111` only picks up
executables, so a non-executable `_lib.sh` is invisible to `dot`).

### 4. `$HOME/Code/dotly` is hardcoded in two places

`config/.bashrc`:
```bash
export DOTLY_PATH="$HOME/Code/dotly"
```

`scripts/install/dot`:
```bash
DOTLY_PATH="$HOME/Code/dotly"
```

On a machine where repos live under `~/src/` or `~/workspace/`, both break. Add a
fallback so the env var can be overridden before sourcing:

```bash
DOTLY_PATH="${DOTLY_PATH:-$HOME/Code/dotly}"
```

### 5. The `$script_dir/../..` pattern is depth-coupled

Every config script computes repo root as:

```bash
repo_root=$(cd -- "$script_dir/../.." && pwd)
```

This only works at exactly `scripts/config/<name>`. If a script ever needs to live at
`scripts/config/utils/<name>`, repo root resolves to the wrong directory — and it fails
silently because `cd` succeeds and just lands in the wrong place.

A more robust pattern walks upward looking for `.git`:

```bash
find_repo_root() {
  local dir=$1
  while [[ "$dir" != "/" ]]; do
    [[ -d "$dir/.git" ]] && { echo "$dir"; return; }
    dir=$(dirname "$dir")
  done
  echo "Error: not inside a git repo" >&2; return 1
}
repo_root=$(find_repo_root "$script_dir")
```

This is future-proof regardless of where scripts live.

### 6. The install script clones dotly over HTTPS

```bash
DOTLY_REPO="https://github.com/gtrabanco/dotly.git"
```

Your dotfiles clone instruction uses SSH (`git@github.com:...`). Mixing protocols is
inconsistent and can break on machines where HTTPS is blocked or where SSH agent
forwarding is in use. Since dotly is a public read-only dependency, HTTPS is actually
fine here — but it's worth being intentional about why rather than accidental.

---

## The One Bigger Insight

The dotly framework vs. your personal dotfiles is the right two-repo split. What's worth
studying is **why it works**:

The `bin/dot` resolution order (`$DOTFILES_PATH` checked first, then `$DOTLY_PATH`) is a
plugin architecture implemented in 5 lines of bash. If you ever want to override a dotly
built-in, you just create `scripts/git/commit` in your dotfiles and it silently wins. No
monkey-patching, no inheritance, no flags. Just convention + filesystem.

That's the key insight: **the best architectures are the ones where adding a feature
requires adding a file, not modifying existing code.**
