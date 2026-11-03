# Dotfiles toolkit architecture

The repository owns its Bash dispatcher and config-management scripts. There is
no external Dotly dependency. GNU utilities and Bash are required; Git handles
tracking, `fzf` is needed only for interactive selection, and `just` is optional.
Python 3 is used by the regression tests, not by the toolkit itself.

## Dispatch and wrappers

`bin/dot` discovers executable regular files at exactly
`scripts/<context>/<name>`. Names and contexts beginning with `_` are private;
symlinked commands, directories, and non-executable files are excluded. Listing,
shortcuts, and explicit context dispatch use the same discovery result. Names
are compared literally, including characters such as `.` and `[`.

`dot <context> <script> [args...]` selects a command explicitly.
`dot <script> [args...]` works when its name is unambiguous. Missing or ambiguous
commands report an error. `dot` and `dot <context>` open an `fzf` picker. Missing
`fzf` is reported without installing anything. Cancellation returns nonzero.

The dispatcher resolves its own location using GNU `readlink -f`, which handles
relative symlink chains. `DOTFILES_PATH` can override the discovered root.
`sdot` resolves its own location and executes its sibling `dot`; it inherits the
environment and does not source `.bashrc`.

Selected commands run as separate processes with arguments in `"$@"`, and their
exit status reaches the caller. `dot --help` prints the dispatcher's usage;
`dot config adopt -h` extracts the command's `##?` comments without executing it.

The picker reads a whitespace-separated argument array with `read -r -a`.
It performs no shell evaluation, quote interpretation, variable substitution,
or wildcard expansion. For arguments containing spaces, use direct invocation:

```bash
dot config adopt "$HOME/.config/my app/settings"
```

## Path contracts

`scripts/config/_paths.sh` is a non-executable library. Sourcing it only defines
functions: it does not inspect files, write data, change shell options, or assign
global state. Helpers accept explicit arguments, use local variables, print
results to stdout, send errors to stderr, and return a status.

- `config_home_path INPUT HOME ROOT` expands a leading `~/` and lexically
  normalizes the location using GNU `realpath -ms`. It does **not** follow the
  final symlink. Paths must be inside home and outside the repository; resolved
  parent directories are checked too, so directory aliases cannot bypass this.
- `config_repo_path INPUT HOME ROOT` applies the single mapping
  `$HOME/<relative>` → `<root>/config/<relative>`. It also rejects config parent
  directories that escape the config tree through symlinks.
- `config_link_matches HOME_PATH REPO_PATH` separately follows targets to check
  whether an existing, working home symlink belongs to the expected file.
- `config_tracked_files ROOT` emits Git's null-delimited config filenames and
  preserves Git's failure status.
- `config_backup_path PATH` selects a timestamped backup path and adds a suffix
  when a backup with the same timestamp already exists.

Keeping a link's location separate from its resolved target is essential:
`unadopt ~/.config/app/file` maps the home location into `config/.config/app/file`,
then validates the link. Mapping the resolved repository target would incorrectly
produce a second `config/Code/dotfiles/...` path.

Config entry points locate their library and repository relative to their own
`scripts/config/` directory. This depth is an intentional layout contract.

## Config operations

`adopt` accepts a regular, non-symlink home file, refuses existing repository
paths (including broken symlinks), copies the file, backs up the original, creates
an absolute symlink, and stages the new file with Git.

`adopt-verify` delegates to `adopt --verify`. It prints the same mapping used by
adoption, linking, and unadoption, without writes. Missing paths and adopted
symlinks can both be previewed.

`unadopt` accepts only a working symlink to its expected repository file. It
checks `git rm --dry-run` before changes, copies the contents into a unique
sibling temporary file, stages removal with `git rm`, then replaces the home
symlink with the copy. Git's protection for uncommitted changes remains enabled:
commit an adoption or later edits before unadopting. Foreign and broken links
are rejected. If final replacement fails, the temporary copy is retained and
its location is reported.

`link-config` has three outcomes:

| Status | Meaning |
| --- | --- |
| 0 | Created a link |
| 2 | Already linked, or replacement was declined (including prompt EOF) |
| 1 | Failed |

Existing regular files are backed up. Differing contents require confirmation
unless `--force` is used. Foreign or broken symlinks are rejected even with
`--force`. Direct callers must handle status 2 as a skip rather than a failure.

`bootstrap` obtains the full tracked-file list before making changes, calls
`link-config`, and counts these outcomes. It continues past per-file failures
and returns failure when any operation fails. `__pycache__` entries are ignored.
The summary includes the monitor override operation.

The monitor destination `~/.config/hypr/monitors-local.conf` is managed separately:
`monitors-local.<hostname>.conf` is selected if present, with
`monitors-local.default.conf` as fallback. Existing monitor symlinks are refreshed
without prompting, as before; existing regular monitor files are backed up.
A missing monitor source is an error. `--dry-run` prints planned links without
creating directories, links, backups, or temporary files.

`drift` uses the shared mapping and link checks, retains `.driftignore` globs,
and reports missing links, candidate regular files, and leftover backups.
Repo-tracked symlinks remain excluded from target checks. Tracked files and
managed-directory entries are enumerated with null delimiters so whitespace in
filenames does not split entries. Git and directory-discovery failures are
reported instead of being mistaken for a clean result.

## Shell error handling

`set -euo pipefail` is a useful baseline, not a complete error-handling strategy.
`-e` has exceptions in `if`, `!`, `&&`, `||`, and other conditional contexts.
Calling a function as an `if` condition can disable errexit throughout that
function. Command substitutions also have errexit subtleties; a failing process
substitution does not make its consuming loop fail.

Helpers therefore explicitly check dependent operations and return failures.
Bootstrap captures child statuses in an `if` and distinguishes skips from errors.
Discovery uses a checked pipeline with `pipefail` and Bash `lastpipe`, which keeps
`mapfile`'s array in the current shell. A partially failing Git command is rejected
before its results are used. No failure is hidden behind `mapfile < <(git ...)`.

Subprocess isolation protects the caller's shell state; it does not replace
explicit error checks or transactional filesystem operations. Backups protect
contents, but an I/O or Git staging failure can still leave partially completed
work that must be inspected.

## Validation

```bash
just test
just --list
```

`just test` runs Bash syntax checks and the Python standard-library regression
suite. Tests copy toolkit files into temporary repositories with isolated home
directories and stubbed external commands; they never link into the real home or
stage the real repository. ShellCheck runs when installed. Tests cover dispatch,
wrappers, path mappings, adoption round trips, backups, foreign/broken links,
bootstrap counts, monitor selection, dry runs, and discovery failures.
