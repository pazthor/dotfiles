# Dotfiles Migration Lifecycle (chezmoi)

This repository now standardizes migration work through explicit `make` targets backed by `chezmoi`.

## Command Surface

Run from repo root:

```sh
make migrate-inventory  # generate manifest of candidate files
make migrate-import     # run `chezmoi add --follow` for each manifest entry
make migrate-diff       # inspect pending chezmoi changes
make migrate-apply      # apply managed state to $HOME
make migrate-verify     # check for missing paths / non-symlink targets
```

## Typical Workflow

1. **Generate inventory**
   ```sh
   make migrate-inventory
   ```
   Review `.cache/chezmoi-migration-manifest.txt` and remove anything you don't want to import.

2. **Import into chezmoi source state**
   ```sh
   make migrate-import
   ```

3. **Review**
   ```sh
   make migrate-diff
   ```

4. **Apply**
   ```sh
   make migrate-apply
   ```

5. **Verify**
   ```sh
   make migrate-verify
   ```

## Notes

- `config/` paths map to `$HOME/<relative-path>` (for example, `config/.local/bin/yda` -> `~/.local/bin/yda`).
- Legacy `.config/` paths, if any remain, map to `$HOME/.config/<relative-path>`.
- `migrate-import` depends on `migrate-inventory`, so the manifest always refreshes first.
- `migrate-verify` fails if inventory paths are missing or no longer symlinks.
- After `git pull`, use `just sync` (or `scripts/bootstrap`) to create any newly added symlinks in `$HOME`.
- The historical typo target `adot-config` is still available as a deprecated alias for `adopt-config`.
