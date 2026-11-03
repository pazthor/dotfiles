#!/usr/bin/env bash
# Delete stale local git branches: last commit older than N days AND no branch
# on any remote (never pushed, or remote branch deleted after merge).
# Only branches already merged (reachable from HEAD or origin/HEAD) are deleted;
# pass --include-unmerged to also delete unmerged ones.
# Default is a dry run. Pass --apply to actually delete.
# Every deletion is logged with its tip SHA so it can be restored:
#   git -C <repo> branch <name> <sha>
set -euo pipefail

DAYS=30
APPLY=0
INCLUDE_UNMERGED=0
ROOTS=("$HOME/Code" "$HOME/Projects")
PROTECT='^(main|master|develop|dev|staging|production|release.*)$'
LOG="$HOME/.local/state/git-branch-cleanup.log"
mkdir -p "$(dirname "$LOG")"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --include-unmerged) INCLUDE_UNMERGED=1 ;;
    --days) DAYS="$2"; shift ;;
    --root) ROOTS=("$2"); shift ;;
    -h|--help) sed -n "2,9p" "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

cutoff=$(( $(date +%s) - DAYS*86400 ))
total=0
skipped=0
mode=$([[ $APPLY == 1 ]] && echo "DELETING" || echo "DRY RUN (use --apply to delete)")
echo "== git branch cleanup: older than $DAYS days, no remote branch — $mode"

while IFS= read -r gitdir; do
  repo="${gitdir%/.git}"
  cd "$repo" || continue
  # refresh remote refs so deleted remote branches show as gone
  git remote | grep -q . && git fetch --all --prune --quiet 2>/dev/null || true
  current=$(git symbolic-ref --short -q HEAD || echo "")
  worktree_branches=$(git worktree list --porcelain | sed -n 's#^branch refs/heads/##p')
  printed_header=0

  while IFS='|' read -r br ts; do
    [[ -z "$br" ]] && continue
    [[ "$br" == "$current" ]] && continue
    [[ "$br" =~ $PROTECT ]] && continue
    grep -qxF "$br" <<<"$worktree_branches" && continue
    (( ts > cutoff )) && continue
    # skip if any remote has a branch with this name
    if git for-each-ref --format='%(refname)' "refs/remotes/*/$br" | grep -q .; then continue; fi
    sha=$(git rev-parse --short "refs/heads/$br")
    age=$(( ( $(date +%s) - ts ) / 86400 ))
    merged=unmerged
    for base in HEAD refs/remotes/origin/HEAD; do
      git rev-parse -q --verify "$base" >/dev/null || continue
      git merge-base --is-ancestor "refs/heads/$br" "$base" 2>/dev/null && { merged=merged; break; }
    done
    if [[ $merged == unmerged && $INCLUDE_UNMERGED == 0 ]]; then skipped=$((skipped+1)); continue; fi
    if [[ $printed_header == 0 ]]; then echo; echo "## $repo"; printed_header=1; fi
    printf '  %-45s %4sd  %s  %s\n' "$br" "$age" "$sha" "$merged"
    total=$((total+1))
    if [[ $APPLY == 1 ]]; then
      git branch -D "$br" >/dev/null
      echo "$(date '+%F %T') $repo $br $(git rev-parse "$sha" 2>/dev/null || echo "$sha") $merged" >> "$LOG"
    fi
  done < <(git for-each-ref --format='%(refname:short)|%(committerdate:unix)' refs/heads)
done < <(find "${ROOTS[@]}" -maxdepth 4 -type d -name .git -not -path '*/node_modules/*' -not -path '*/vendor/*' 2>/dev/null)

echo
echo "Kept $skipped unmerged stale branch(es); use --include-unmerged to list or delete them."
echo "$total branch(es) $([[ $APPLY == 1 ]] && echo deleted || echo 'would be deleted')."
[[ $APPLY == 1 && $total -gt 0 ]] && notify-send "Git branch cleanup" "Deleted $total stale branches (log: $LOG)" 2>/dev/null || true
