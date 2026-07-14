# Dotfiles Architecture — Staff Engineer Study Guide

## System Architecture

A single repo (`~/Code/dotfiles`) owns everything. The `dot` command is a
44-line custom dispatcher that lives inside the repo itself — no external
framework dependency.

```
~/Code/dotfiles/
├── bin/dot              ← the dispatcher (entry point)
├── bin/sdot             ← env-free wrapper that sources .bashrc then calls dot
├── config/              ← files symlinked into $HOME (config/.bashrc → ~/.bashrc, etc.)
└── scripts/
    ├── config/          ← dotfile management (adopt, bootstrap, drift, …)
    ├── git/             ← git workflow helpers
    ├── install/         ← one-time setup scripts
    ├── media/           ← media download tools
    └── system/          ← system-level setup
```

**Dispatch flow:**

```
dot config adopt ~/.config/hypr/bindings.conf
  → finds scripts/config/adopt (executable, depth 2)
  → runs it as a subprocess with "$@"
```

`DOTFILES_PATH` is either set in the environment or self-discovered by the
dispatcher at runtime from its own location via `BASH_SOURCE`. No external
framework, no second repo, no `DOTLY_PATH`.

---

## Best Practices in Use

### 1. `set -euo pipefail` on every script

```bash
set -euo pipefail
```

- `-e`: exit on any command failure — no silent swallowing of errors
- `-u`: unset variables are errors, not empty strings (`rm -rf "$DIR/"` with
  unset `$DIR` becomes `rm -rf /` without this flag)
- `-o pipefail`: a pipe fails if any stage fails, not just the last one

This is the baseline for production-quality bash. Every script in this repo
has it.

### 2. Two levels of self-location via `BASH_SOURCE`

**In the dispatcher** (`bin/dot`) — self-discovers the repo root by following
its own symlink chain:

```bash
_self="${BASH_SOURCE[0]}"
while [[ -L "$_self" ]]; do _self="$(readlink -- "$_self")"; done
export DOTFILES_PATH="${DOTFILES_PATH:-$(cd -- "$(dirname -- "$_self")/.." && pwd)}"
```

This means `dot` works correctly even when symlinked into `~/.local/bin/dot`
or anywhere else in `$PATH` — no env var required.

**In individual scripts** — self-locate relative to the script file:

```bash
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
```

The `cd && pwd` pattern resolves symlinks to an absolute path. `--` after
`dirname` guards against directory names starting with `-`. `BASH_SOURCE[0]`
is used instead of `$0` because `$0` breaks when a script is sourced.

### 3. `##?` comment blocks for inline help

Every script opens with `##?` lines that describe its usage:

```bash
##? Usage:
##?   adopt <path>
##?   adopt --verify [<path>]
##?
##? Options:
##?   --verify   Preview mapping without importing.
```

The dispatcher intercepts `-h` / `--help` before calling the script and
extracts these lines with a single grep — no external tool needed:

```bash
_help() { grep "^##?" "$1" 2>/dev/null | cut -c 5- || true; }
```

Running `dot config adopt -h` prints the help. Adding help to a new script
requires zero changes to the dispatcher — just write the `##?` lines.

Scripts also keep a `usage()` function for direct invocation (`./scripts/config/adopt -h`).
Both coexist: `##?` serves `dot`, `usage()` serves direct calls.

### 4. Always subprocess — never source

The dispatcher always runs scripts as child processes:

```bash
"$target" "$@"    # fork → child runs → child exits → parent continues
```

It never uses `. "$target"` (source). This means:

- `exit` in any script terminates the child, not the shell
- `set -euo pipefail` at the top of a script affects only that child
- Scripts are fully isolated — no side effects on the calling environment

This is the reason the scripts can use `exit 1` and `set -euo pipefail` freely
without any special conventions.

### 5. Idempotency as a first-class design goal

Every state-changing script is safe to re-run:

- `bootstrap` — checks if already linked before linking
- `adopt` — refuses to overwrite an existing repo file
- `install/dot` — bootstrap is itself idempotent
- `link-config` — detects "already linked" as a distinct non-error exit code

This is the property that makes automation trustworthy. A script you can only
run once is a liability.

### 6. Semantic exit codes

`link-config` uses three exit codes with distinct meanings:

- `0` — linked successfully
- `1` — error
- `2` — skipped (already correctly linked)

`bootstrap` calls `link-config` in a loop and counts each outcome separately,
reporting `linked=N skipped=N failed=N`. Callers react to exit codes, not
parsed output.

### 7. Stderr for diagnostics, stdout for data

```bash
echo "Error: unsupported path: $source_path" >&2   # stderr: human message
printf '%s\n' "${candidates[0]}"                    # stdout: machine-usable result
```

Errors go to stderr. Usable output goes to stdout. Safe to pipe: `dot config
adopt-verify | grep config` never mixes error messages into the data stream.

### 8. Backup before destructive operations

```bash
timestamp=$(date +%Y%m%d%H%M%S)
backup_path="$source_path.bak.$timestamp"
mv -- "$source_path" "$backup_path"
```

`adopt` and `link-config` never delete — they rename with a timestamp. `drift`
surfaces these as `leftover:` entries. The chain: backup → operate → user
reviews → user deletes. No data loss path.

### 9. `git -C <path>` instead of `cd`

```bash
git -C "$repo_root" add "$repo_path"
git -C "$repo_root" ls-files -- 'config/'
```

Never `cd` inside a script that other scripts call. `-C` runs git in a
specific directory without changing the process working directory. Composable,
no side effects.

### 10. `readonly` on constants

```bash
readonly PACKAGE_ROOTS=(
  "config:$HOME"
)
```

Prevents accidental mutation later in the script. Used on constants that define
the script's core behavior — package roots, repo names, etc.

---

## Philosophy / Mental Models

### Convention over configuration

The dispatcher works because everyone agrees: scripts live at
`scripts/<context>/<name>`, are executable files, and nothing else. No
registry, no manifest, no config file. The filesystem *is* the configuration.
Add a script and it immediately appears in `dot` and the FZF picker.

The depth constraint (exactly 2 levels, `-mindepth 2 -maxdepth 2`) is part of
the convention. Violate it and the script disappears silently — a deliberate
trade-off: simple discovery in exchange for a structural rule you internalize
once.

The `_*` filename prefix is the escape hatch: files named `_lib.sh` are not
executable by convention so `find -perm /+111` skips them, making them safe
as shared library includes invisible to `dot`.

### Locality — scripts own their own paths

No script depends on `DOTFILES_PATH` being set to find its siblings.
`bootstrap` calls `$script_dir/link-config`, not
`$DOTFILES_PATH/scripts/config/link-config`. Move the repo and everything
still works because scripts navigate relative to themselves.

The dispatcher is the only code that needs `DOTFILES_PATH` — and it
self-discovers it, so even that dependency is eliminated at the entry point.

### Composition over monolith

`bootstrap` doesn't implement linking — it calls `link-config` in a loop.
`adopt-verify` doesn't implement verification — it calls `adopt --verify`.
Each script has one job. You can call any piece independently. This is Unix
philosophy: small tools that compose.

### Idempotency enables automation

Any script safe to re-run multiple times can go in CI, in an installer, or be
called by accident. The install script, bootstrap, and adopt are all
idempotent. This is what separates "scripts" from "automation."

### Subprocess isolation keeps scripts simple

Because the dispatcher always forks, scripts never need to worry about
cleaning up after themselves or avoiding `exit`. Each script can be written
as if it owns the process — because it does.

---

## Open Issues (still worth fixing)

### 1. `link-config` uses Python for path normalization

`adopt` and `unadopt` use `readlink -f`:
```bash
normalize_path() { readlink -f -- "$raw"; }
```

`link-config` uses Python:
```bash
normalize_path() {
  python -c 'import os, sys; print(os.path.abspath(os.path.expanduser(sys.argv[1])))' "$raw"
}
```

`readlink -f` follows symlinks to the final target; `os.path.abspath` doesn't.
This is a latent inconsistency — fix `link-config` to match its siblings.

### 2. `PACKAGE_ROOTS` is copy-pasted into three scripts

`adopt`, `link-config`, and `unadopt` each declare:
```bash
readonly PACKAGE_ROOTS=("config:$HOME")
```

Adding a second package root requires updating three files. The fix is a
shared non-executable library:

```bash
# scripts/config/_lib.sh  (chmod -x, invisible to dot)
PACKAGE_ROOTS=("config:$HOME")
```

Then each script sources it. The `_*` prefix keeps it out of the FZF picker.

### 3. `$script_dir/../..` is depth-coupled

Config scripts compute repo root as:
```bash
repo_root=$(cd -- "$script_dir/../.." && pwd)
```

This only works at exactly `scripts/config/<name>`. A script at
`scripts/config/utils/<name>` silently resolves to the wrong directory.

A more robust alternative walks upward looking for `.git`:

```bash
find_repo_root() {
  local dir=$1
  while [[ "$dir" != "/" ]]; do
    [[ -d "$dir/.git" ]] && { echo "$dir"; return; }
    dir=$(dirname "$dir")
  done
  return 1
}
repo_root=$(find_repo_root "$script_dir")
```

---

## What Was Resolved

| Issue | Resolution |
|---|---|
| `yt-dlp` was a notes file with no shebang | Rewritten as a real script taking a URL argument |
| dotly was a dormant external dependency | Replaced with a 44-line custom dispatcher in `bin/dot` |
| `DOTLY_PATH` hardcoded in two files | Removed entirely — no external framework |
| dotly HTTPS clone in install script | Install script removed clone step — nothing to clone |
| PATH order put dotly before dotfiles | Fixed — `$DOTFILES_PATH/bin` now comes first |

---

## The Core Insight

The dispatcher implements a plugin architecture in 44 lines:

```
scripts/<context>/<name>  →  executable file  →  appears in dot
```

No registration. No config. No framework to update. Adding a script adds a
capability. Removing a script removes it. The filesystem is the source of
truth.

**The best architectures are the ones where adding a feature requires adding
a file, not modifying existing code.**
