# Stow → chezmoi migration script

Use `scripts/migrate-stow-to-chezmoi` to import files currently managed by Stow into chezmoi.

## What it does

1. Discovers candidate files under Stow package directories at repository root (`config/` today, plus any future package directories).
2. Builds a manifest mapping:
   - `repo_source` (path in this repository, relative to repo root)
   - `target_home` (expected live path under `$HOME`)
3. Supports dry-run mode (default) that prints planned commands:
   - `chezmoi add --follow -- <target>`
4. Supports import mode (`--import`) that executes `chezmoi add --follow`.
5. Logs successes/failures and exits non-zero if any mapped target is missing, unreadable, or import fails.

## Examples

```bash
# Dry-run + JSON manifest
scripts/migrate-stow-to-chezmoi \
  --dry-run \
  --manifest /tmp/stow-migration.json

# Import + CSV manifest
scripts/migrate-stow-to-chezmoi \
  --import \
  --format csv \
  --manifest /tmp/stow-migration.csv
```

## Assumptions and caveats

- **Stow package model**: every top-level directory (except known non-packages like `docs/` and `scripts/`) is treated as a package root.
- **Target path mapping**: for a package file `<package>/<relpath>`, the target is assumed to be `$HOME/<relpath>`.
- **Hostname overlays**: host-specific overlays (for example, `hosts/<hostname>/...`) are only imported if they exist as package directories and are not excluded; there is no automatic hostname filtering in this script.
- **Excludes**:
  - Built-in excludes skip likely secrets/artifacts (`*.age`, `*.gpg`, `*.key`, `*.pem`, `*.sops.*`, temp/backup editor files).
  - Add extra excludes with `--exclude '<glob>'`.
- **Secrets**: encrypted/secret files are intentionally excluded by default; import them manually if desired.
- **Generated files**: generated/transient files should be excluded with `--exclude` or removed from package trees before migration.
- **Symlink following**: `chezmoi add --follow` records the target file contents of symlinks.

## Safety tips

- Always run `--dry-run` first and inspect the manifest.
- Review excluded paths and rerun with custom `--exclude` patterns if needed.
- Run imports in smaller batches with `--package <name>` if you want incremental migration.
