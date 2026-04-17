SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

# Adopt an existing local config file into this repository.
adopt-config:
	./scripts/adopt-config

# Backward-compatible alias for adopt-config.
adot-config: adopt-config

# Initialize a chezmoi source directory from this dotfiles repo.
chezmoi-init:
	chezmoi init --source="$(CURDIR)"

# Migrate existing managed files into the chezmoi source state.
chezmoi-migrate:
	./scripts/chezmoi-migrate

# Show pending changes between source state and destination.
chezmoi-diff:
	chezmoi diff

# Apply chezmoi-managed dotfiles to the destination.
chezmoi-apply:
	chezmoi apply

# Show chezmoi source and destination status.
chezmoi-status:
	chezmoi status

# Legacy GNU Stow wrapper for packaging symlinks.
legacy-stow-pack:
	./scripts/stow-pack
