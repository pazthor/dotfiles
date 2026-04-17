# Migrating Stow-Managed Dotfiles to chezmoi

This repository includes `scripts/migrate-stow-to-chezmoi` to support a controlled migration from Stow package layouts into chezmoi.

The migration flow is intentionally policy-driven:

1. Enumerate **git-tracked files** from selected Stow modules.
2. Compute each file's target path under `$HOME`.
3. Skip anything matching exclusion policy.
4. Import only paths that match the approved-path policy.
5. Save an audit log + summary for repeatability.

## Files

- `scripts/migrate-stow-to-chezmoi`
  - migration runner.
- `scripts/migrate-stow-to-chezmoi.approved`
  - allow-list policy (approved target path globs).
- `scripts/migrate-stow-to-chezmoi.exclude`
  - deny-list policy (excluded target path globs).
- `logs/chezmoi-migration/`
  - timestamped logs and tabular summaries (`latest.*` aliases are updated each run).

## Usage

Run from repository root:

```bash
scripts/migrate-stow-to-chezmoi --dry-run hypr waybar
```

Apply mode (actual import):

```bash
scripts/migrate-stow-to-chezmoi hypr waybar
```

Custom policy/log locations:

```bash
scripts/migrate-stow-to-chezmoi \
  --allow-file ./scripts/migrate-stow-to-chezmoi.approved \
  --exclude-file ./scripts/migrate-stow-to-chezmoi.exclude \
  --log-dir ./logs/chezmoi-migration \
  hypr waybar
```

## Policy semantics

Both policy files are shell-glob based and matched against paths **relative to `$HOME`**.

Example mapping:

- source file: `hypr/.config/hypr/hyprland.conf`
- computed target path: `.config/hypr/hyprland.conf`
- computed absolute path: `$HOME/.config/hypr/hyprland.conf`

### Approved policy (`*.approved`)

A target path is eligible for import only if it matches one of the approved patterns (when the file exists).

### Exclusion policy (`*.exclude`)

Any excluded match is skipped even if it also appears in approved patterns.

Recommended exclusions include:

- monitor auto-generated configs,
- cache directories,
- runtime state,
- transient app artifacts.

## Audit output

Every run emits:

- `logs/chezmoi-migration/<timestamp>.log`
- `logs/chezmoi-migration/<timestamp>-summary.tsv`
- `logs/chezmoi-migration/latest.log`
- `logs/chezmoi-migration/latest-summary.tsv`

The summary TSV contains one row per evaluated file with status values such as:

- `planned` (dry-run would import),
- `added` (imported),
- `skipped-excluded`,
- `skipped-unapproved`,
- `missing-target`,
- `failed`.

This gives you a repeatable/importable record for later review.
