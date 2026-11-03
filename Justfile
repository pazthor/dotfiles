set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

dotfiles := env_var_or_default("DOTFILES", justfile_directory())

# Show available recipes
default:
    @just --list

# Install dot command (bootstrap this repository) — run this on a new machine after cloning dotfiles
install-dot:
    {{dotfiles}}/scripts/install/dot

# Bootstrap or refresh repo-backed symlinks in $HOME
bootstrap *args:
    {{quote(dotfiles)}}/scripts/config/bootstrap "$@"

# Sync symlink-managed files after pulling changes from git
sync *args:
    {{quote(dotfiles)}}/scripts/config/bootstrap "$@"

# Pull latest from git and link any new/missing configs
update *args:
    cd {{quote(dotfiles)}} && git pull --rebase
    {{quote(dotfiles)}}/scripts/config/bootstrap "$@"

# Install/update InShellisense shell completions
install-inshellisense:
    {{dotfiles}}/scripts/install/inshellisense

# Adopt a config file into the repo
adopt path:
    {{quote(dotfiles)}}/scripts/config/adopt "$1"

# Preview or verify a path mapping
verify path="":
    {{quote(dotfiles)}}/scripts/config/adopt-verify ${1:+"$1"}

# download a video from copy url
ydv:
    {{dotfiles}}/scripts/media/yt-dlp

# Check received DNS servers and AdGuard filtering without changing the network
test-adguard interface="wlp195s0" server="192.168.0.122":
    @bash "{{dotfiles}}/scripts/system/test-adguard.sh" "{{interface}}" "{{server}}"

# Run isolated toolkit regressions, syntax checks, and optional ShellCheck
test:
    @bash {{quote(dotfiles)}}/tests/run
