# Sourcing vs Subprocess — Why dotSloth New-Style Breaks Naive Scripts

This document shows the same script written three ways:
1. **Naive** — how you'd naturally write it (breaks under dotSloth)
2. **dotSloth-safe** — the workaround dotSloth requires
3. **Subprocess** — the dotfiles approach, where the naive version just works

The example scenario: a script that validates a dependency, creates a temp
file, does work, and cleans up on failure.

---

## The scenario

```
dot install check-and-run <tool>

Checks that <tool> is installed.
Creates a temp workspace.
Runs the tool.
Cleans up on any failure.
```

---

## Version 1 — Naive bash (breaks silently under dotSloth)

```bash
#!/usr/bin/env bash
set -euo pipefail          # ← PROBLEM A

required="${1:-}"

if [[ -z "$required" ]]; then
  echo "Error: tool name required" >&2
  exit 1                   # ← PROBLEM B
fi

if ! command -v "$required" &>/dev/null; then
  echo "Error: $required not found" >&2
  exit 1                   # ← PROBLEM B
fi

tmpdir=$(mktemp -d)
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT          # ← PROBLEM C

echo "Running $required in $tmpdir"
"$required" --version
```

Under dotSloth this script is **sourced** into the calling shell, not run
as a child process. Three things silently break:

**Problem A — `set -euo pipefail` leaks into the parent shell**

```
before script:  your shell has its own (relaxed) error settings
source script:  set -euo pipefail applied to YOUR shell
after script:   your shell is now running under strict mode permanently

# Any subsequent command that fails (even a missing file test) exits your terminal.
```

**Problem B — `exit` kills the terminal, not the script**

```
you type:   dot install check-and-run nonexistent-tool
dotSloth:   sources the script into your shell
script:     hits exit 1
result:     your entire terminal session closes

# This is equivalent to typing `exit` at the prompt.
```

**Problem C — `trap EXIT` fires when the terminal closes, not when the script ends**

```bash
trap cleanup EXIT   # registers cleanup on the PARENT shell's EXIT signal
# ... script logic runs and returns ...
# tmpdir is NEVER cleaned up here — trap doesn't fire on script return
# tmpdir IS cleaned up when you close the terminal — surprising and late
```

---

## Version 2 — dotSloth-safe workaround

To avoid all three problems under dotSloth, the script must be rewritten
with a wrapping function, `return` instead of `exit`, and `set` moved inside:

```bash
#!/usr/bin/env bash

_check_and_run() {
  set -euo pipefail          # inside the function: affects only this scope
                             # (in practice bash doesn't isolate set flags
                             # inside functions either — still leaks)

  local required="${1:-}"

  if [[ -z "$required" ]]; then
    echo "Error: tool name required" >&2
    return 1                 # ← return, not exit
  fi

  if ! command -v "$required" &>/dev/null; then
    echo "Error: $required not found" >&2
    return 1                 # ← return, not exit
  fi

  local tmpdir
  tmpdir=$(mktemp -d)

  local cleanup_done=0
  _cleanup() {
    (( cleanup_done )) && return
    cleanup_done=1
    rm -rf "$tmpdir"
  }
  trap _cleanup RETURN       # RETURN fires when function returns — not EXIT

  echo "Running $required in $tmpdir"
  "$required" --version

  _cleanup
  trap - RETURN
}

_check_and_run "$@"
local exit_code=$?

# Must manually unset to avoid polluting the parent shell's function namespace
unset -f _check_and_run
unset -f _cleanup

return $exit_code
```

**This works, but the cost is real:**

- Every `exit` becomes `return` — you must remember this everywhere
- `trap EXIT` is replaced by `trap RETURN` (different semantics, subtler bugs)
- Every top-level variable must be `local` (otherwise it persists in the parent shell)
- Every function defined in the script persists in the parent until `unset -f`
- `set -euo pipefail` inside a function still leaks flags to the parent in some
  bash versions
- Scripts can no longer be run directly (`./scripts/install/check-and-run`) with
  the same behavior — `return` at the top level of a directly-executed script is
  an error

---

## Version 3 — Subprocess (current dotfiles approach)

The dispatcher in `bin/dot` always forks a child process:

```bash
"$target" "$@"    # never:  . "$target"
```

So the naive version works exactly as written:

```bash
#!/usr/bin/env bash
set -euo pipefail

##? Usage:
##?   check-and-run <tool>
##?
##? Check that <tool> is installed and run it in a temp workspace.

required="${1:-}"

if [[ -z "$required" ]]; then
  echo "Error: tool name required" >&2
  exit 1           # ← exits the child process, not the terminal
fi

if ! command -v "$required" &>/dev/null; then
  echo "Error: $required not found" >&2
  exit 1           # ← exits the child process, not the terminal
fi

tmpdir=$(mktemp -d)
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT  # ← fires when THIS child process exits — correct

echo "Running $required in $tmpdir"
"$required" --version
```

**What each problem looks like here:**

| Problem | dotSloth (sourced) | dotfiles (subprocess) |
|---|---|---|
| `set -euo pipefail` | Leaks into parent shell permanently | Isolated to child process, gone on exit |
| `exit 1` | Closes the terminal | Terminates the child, parent continues |
| `trap cleanup EXIT` | Fires when terminal closes | Fires when child process exits — correct |
| Top-level variables | Persist in parent shell | Isolated, discarded on child exit |
| Function definitions | Persist in parent shell | Isolated, discarded on child exit |
| Direct invocation (`./script`) | Same as sourced — breaks again | Works identically to `dot install check-and-run` |

---

## The mental model

A **sourced script** is like inlining the code at the call site. Whatever the
script does, it does to the shell that called it. It's the same process.

```
your shell ──── source script ────► your shell (now modified)
                                     set flags changed
                                     variables added
                                     functions added
                                     exit = your shell exits
```

A **subprocess** is like calling a function in a separate process. It gets a
copy of the environment, runs, and disappears. The parent is unchanged.

```
your shell ──── fork ────► child process (copy of env)
    │                           set flags: isolated
    │                           variables: isolated
    │                           exit: child disappears
    └──── wait ◄─── exit code ──────────────────────┘
```

---

## Why dotSloth went with sourcing

dotSloth's new-style execution model exists so scripts can modify the calling
shell — set variables, change directory, export values. That's useful for
scripts like `cd-to-project` that need to change the current directory of the
calling shell.

But this only works because those scripts are written *knowing* they will be
sourced. The function-wrapping pattern, `return` instead of `exit`, and `local`
for every variable are non-negotiable — the whole model collapses if any script
uses `exit` or leaks a variable.

For a dotfiles setup where scripts manage files, install tools, and run
commands — and don't need to modify the calling shell's state — subprocess
execution is simpler, safer, and requires no special conventions.
