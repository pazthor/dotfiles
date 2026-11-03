# shellcheck shell=bash
# Shared path contracts. Sourcing only defines functions; no I/O or shell options.
# GNU realpath/readlink are required. Paths are printed on stdout, errors on stderr.

config_home_path() {
  local raw=$1 home=$2 root=$3 path parent physical_home physical_root
  case $raw in '~') raw=$home ;; '~/'*) raw="$home/${raw:2}" ;; esac
  home=$(realpath -ms -- "$home") || return 1
  root=$(realpath -ms -- "$root") || return 1
  path=$(realpath -ms -- "$raw") || return 1
  if [[ "$path" != "$home/"* || "$path" == "$root" || "$path" == "$root/"* ]]; then
    printf 'Error: expected a home path outside the repository: %s\n' "$path" >&2
    return 1
  fi
  # Follow parent directories for containment checks, never the leaf symlink.
  parent=$(realpath -m -- "${path%/*}") || return 1
  physical_home=$(realpath -m -- "$home") || return 1
  physical_root=$(realpath -m -- "$root") || return 1
  if [[ "$parent" != "$physical_home" && "$parent" != "$physical_home/"* ]] ||
     [[ "$parent" == "$physical_root" || "$parent" == "$physical_root/"* ]]; then
    printf 'Error: home parent resolves outside home or inside the repository: %s\n' "$path" >&2
    return 1
  fi
  printf '%s\n' "$path"
}

config_repo_path() {
  local input=$1 home=$2 root=$3 path dest parent physical_config
  path=$(config_home_path "$input" "$home" "$root") || return 1
  home=$(realpath -ms -- "$home") || return 1
  root=$(realpath -ms -- "$root") || return 1
  dest="$root/config/${path#"$home/"}"
  parent=$(realpath -m -- "${dest%/*}") || return 1
  physical_config=$(realpath -m -- "$root/config") || return 1
  if [[ "$parent" != "$physical_config" && "$parent" != "$physical_config/"* ]]; then
    printf 'Error: config parent resolves outside config/: %s\n' "$dest" >&2
    return 1
  fi
  printf '%s\n' "$dest"
}

config_link_matches() {
  local home_path=$1 repo_path=$2 current expected
  [[ -L "$home_path" && -e "$home_path" && -e "$repo_path" ]] || return 1
  current=$(readlink -f -- "$home_path") || return 1
  expected=$(readlink -f -- "$repo_path") || return 1
  [[ "$current" == "$expected" ]]
}

config_tracked_files() {
  local root=$1
  git -C "$root" ls-files -z -- config/
}

config_backup_path() {
  local path=$1 backup stamp
  stamp=$(date +%Y%m%d%H%M%S) || return 1
  backup="$path.bak.$stamp"
  while [[ -e "$backup" || -L "$backup" ]]; do backup+='.1'; done
  printf '%s\n' "$backup"
}
