#!/usr/bin/env bash
# End-of-day work summary: commits, active repos, changed files, notes. Writes to ~/Documents/daily-summaries/YYYY-MM-DD.md
# Usage: daily-summary.sh [YYYY-MM-DD]   (defaults to today)
set -uo pipefail
STATE="$HOME/.local/state/daily-summary.last"; mkdir -p "$(dirname "$STATE")"
if [ -n "${1:-}" ]; then DAY="$1"; SINCE="$1 00:00"; UNTIL="$(date -d "$1 +1 day" +%F) 00:00"; SCHEDULED=0
else DAY=$(date +%F); UNTIL=$(date '+%F %H:%M'); SINCE=$(cat "$STATE" 2>/dev/null || date -d '24 hours ago' '+%F %H:%M'); SCHEDULED=1; fi
OUT_DIR="$HOME/Documents/daily-summaries"; mkdir -p "$OUT_DIR"; OUT="$OUT_DIR/$DAY.md"
ROOTS=("$HOME/Code" "$HOME/Projects" "$HOME/Work")
AUTHOR=$(git config --global user.email 2>/dev/null || true)
{
echo "# Work summary $DAY"; echo; echo "_Covers $SINCE to ${UNTIL}_"; echo
echo "## Commits"
total=0
while IFS= read -r g; do
  repo=$(dirname "$g")
  log=$(git -C "$repo" log --all --since="$SINCE" --until="$UNTIL" ${AUTHOR:+--author="$AUTHOR"} --date=format:%H:%M --pretty='- %ad %s (%h)' 2>/dev/null)
  [ -z "$log" ] && continue
  n=$(echo "$log" | wc -l); total=$((total+n))
  first=$(echo "$log" | tail -1 | awk '{print $2}'); last=$(echo "$log" | head -1 | awk '{print $2}')
  stat=$(git -C "$repo" log --all --since="$SINCE" --until="$UNTIL" ${AUTHOR:+--author="$AUTHOR"} --shortstat --pretty= 2>/dev/null | awk '{f+=$1; i+=$4; d+=$6} END {printf "%d files, +%d/-%d", f, i, d}')
  echo; echo "### ${repo#$HOME/} ($n commits, $first-$last, $stat)"; echo "$log"
done < <(find "${ROOTS[@]}" -maxdepth 3 -name .git -type d 2>/dev/null)
[ $total -eq 0 ] && echo "No commits."
echo; echo "## Uncommitted work"
while IFS= read -r g; do
  repo=$(dirname "$g"); c=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l)
  [ "$c" -gt 0 ] && [ -n "$(find "$repo" -newermt "$SINCE" ! -newermt "$UNTIL" -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/vendor/*' -print -quit 2>/dev/null)" ] && echo "- ${repo#$HOME/}: $c changed files not committed"
done < <(find "${ROOTS[@]}" -maxdepth 3 -name .git -type d 2>/dev/null)
echo; echo "## Files touched by folder"
find "${ROOTS[@]}" "$HOME/Documents" -type f -newermt "$SINCE" ! -newermt "$UNTIL" -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/vendor/*' -not -path '*/.obsidian/*' -not -path '*/daily-summaries/*' 2>/dev/null \
  | sed "s|$HOME/||" | awk -F/ '{print $1"/"$2}' | sort | uniq -c | sort -rn | head -15 | awk '{c=$1; $1=""; print "-"$0": "c" files"}'
echo; echo "## Active time window"
find "${ROOTS[@]}" "$HOME/Documents" -type f -newermt "$SINCE" ! -newermt "$UNTIL" -not -path '*/.git/*' -not -path '*/node_modules/*' -printf '%TH:%TM\n' 2>/dev/null | sort | awk 'NR==1{f=$0} {l=$0} END{ if (f) print "- First change "f", last change "l; else print "- No file activity." }'
echo; echo "## Notes edited"
find "$HOME/Documents" -name '*.md' -newermt "$SINCE" ! -newermt "$UNTIL" -not -path '*/daily-summaries/*' -not -path '*/.obsidian/*' 2>/dev/null | sed "s|$HOME/|- |"
} > "$OUT"

# GitLab merge requests created or updated in the window
MRS=""
if command -v glab >/dev/null; then
  ISO=$(date -u -d "$SINCE" +%Y-%m-%dT%H:%M:%SZ); ISO2=$(date -u -d "$UNTIL" +%Y-%m-%dT%H:%M:%SZ)
  MRS=$(glab api "merge_requests?scope=created_by_me&state=all&updated_after=$ISO&updated_before=$ISO2&per_page=50" 2>/dev/null \
    | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: d=[]
for m in d: print("- {} {} [{}] {}".format(m["references"]["full"], m["title"], m["state"], m["web_url"]))' 2>/dev/null)
fi
{ echo; echo "## Merge requests (created or updated)"; echo "${MRS:-None.}"; } >> "$OUT"

# Standup message (paste-ready)
STANDUP=$(
  echo "*Standup $DAY*"
  echo "Done:"
  while IFS= read -r g; do
    repo=$(dirname "$g")
    git -C "$repo" log --all --since="$SINCE" --until="$UNTIL" ${AUTHOR:+--author="$AUTHOR"} --pretty="%s" 2>/dev/null | tac | sed "s|^|• [$(basename "$repo")] |"
  done < <(find "${ROOTS[@]}" -maxdepth 3 -name .git -type d 2>/dev/null)
  if [ $total -eq 0 ]; then
    if [ -n "$MRS" ]; then echo "$MRS" | sed -E 's|^- ([^ ]+) (.*) \[([a-z]+)\] .*|• MR \1 \2 (\3)|'; else echo "• No commits or MR activity"; fi
  fi
  wip=$(while IFS= read -r g; do repo=$(dirname "$g"); c=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l); [ "$c" -gt 0 ] && [ -n "$(find "$repo" -newermt "$SINCE" ! -newermt "$UNTIL" -type f -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/vendor/*" -print -quit 2>/dev/null)" ] && echo "• $(basename "$repo"): $c files in progress"; done < <(find "${ROOTS[@]}" -maxdepth 3 -name .git -type d 2>/dev/null))
  echo "In progress:"; echo "${wip:-• Nothing pending}"
  BLK=$(python3 "$HOME/bin/mr-blockers.py" 2>/dev/null)
  echo "Blockers:"; echo "${BLK:-• None found}"
)
{ echo; echo "## Standup message"; echo '```'; echo "$STANDUP"; echo '```'; } >> "$OUT"
if command -v wl-copy >/dev/null; then echo "$STANDUP" | wl-copy 2>/dev/null; elif command -v xclip >/dev/null; then echo "$STANDUP" | xclip -selection clipboard 2>/dev/null; fi
[ "$SCHEDULED" -eq 1 ] && echo "$UNTIL" > "$STATE"
echo "$OUT"
command -v notify-send >/dev/null && notify-send "Work summary ready" "$OUT ($total commits)" 2>/dev/null || true
