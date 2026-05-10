set shell := ["bash", "-euo", "pipefail", "-c"]

dotfiles := env_var_or_default("DOTFILES", justfile_directory())

# Show available recipes
default:
    @just --list

# Bootstrap or refresh repo-backed symlinks in $HOME
bootstrap *args:
    {{dotfiles}}/scripts/bootstrap {{args}}

# Sync symlink-managed files after pulling changes from git
sync *args:
    {{dotfiles}}/scripts/bootstrap {{args}}

# Pull latest from git and link any new/missing configs
update *args:
    cd {{dotfiles}} && git pull --rebase
    {{dotfiles}}/scripts/bootstrap {{args}}

# Discover files not yet managed by chezmoi
migrate-inventory:
    cd {{dotfiles}} && make migrate-inventory

# Import all files into chezmoi
migrate-import:
    cd {{dotfiles}} && make migrate-import

# Preview chezmoi changes
migrate-diff:
    cd {{dotfiles}} && make migrate-diff

# Apply chezmoi changes
migrate-apply:
    cd {{dotfiles}} && make migrate-apply

# Verify all files are symlinked
migrate-verify:
    cd {{dotfiles}} && make migrate-verify

# Preview pending chezmoi changes
review:
    {{dotfiles}}/scripts/chezmoi review

# Apply chezmoi changes interactively
apply:
    {{dotfiles}}/scripts/chezmoi apply

# Adopt a config file into the repo
adopt path:
    {{dotfiles}}/scripts/adopt-config {{path}}

# Preview or verify a path mapping
verify path="":
    {{dotfiles}}/scripts/adopt-verify {{path}}

# Run stow-to-chezmoi migration (dry-run by default)
migrate:
    {{dotfiles}}/scripts/migrate-stow-to-chezmoi --dry-run

# Run full import
import:
    {{dotfiles}}/scripts/migrate-stow-to-chezmoi --import

# download a video from copy url 
ydv:
    {{dotfiles}}/scripts/yt-dlp
