set shell := ["bash", "-euo", "pipefail", "-c"]

dotfiles := env_var_or_default("DOTFILES", justfile_directory())

# Show available recipes
default:
    @just --list

# Install dot command (clone dotly + bootstrap) — run this on a new machine after cloning dotfiles
install-dot:
    {{dotfiles}}/scripts/install/dot

# Bootstrap or refresh repo-backed symlinks in $HOME
bootstrap *args:
    {{dotfiles}}/scripts/config/bootstrap {{args}}

# Sync symlink-managed files after pulling changes from git
sync *args:
    {{dotfiles}}/scripts/config/bootstrap {{args}}

# Pull latest from git and link any new/missing configs
update *args:
    cd {{dotfiles}} && git pull --rebase
    {{dotfiles}}/scripts/config/bootstrap {{args}}

# Install/update InShellisense shell completions
install-inshellisense:
    {{dotfiles}}/scripts/install/inshellisense

# Adopt a config file into the repo
adopt path:
    {{dotfiles}}/scripts/config/adopt {{path}}

# Preview or verify a path mapping
verify path="":
    {{dotfiles}}/scripts/config/adopt-verify {{path}}

# download a video from copy url
ydv:
    {{dotfiles}}/scripts/media/yt-dlp
