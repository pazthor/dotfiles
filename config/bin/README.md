# Automations

Three automations, run by systemd user timers. None of them delete files. Times are Mexico City.
Timer files live in `~/.config/systemd/user/`.

## 1. Weekly cleanup: `weekly-cleanup.sh`
Runs every Monday at 09:00 (`weekly-cleanup.timer`).

- Screenshots (`Downloads/image*.png`, `Screenshot*.png`) go to `~/Pictures/Screenshots/YYYY-MM/`.
- Phone photos (`Downloads/YYYYMMDD_*.jpg`) go to `~/Pictures/Phone/YYYY-MM/`.
- WhatsApp videos (`*-whatsapp.mp4`, `WhatsApp Video*.mp4`) go to `~/Videos/WhatsApp/YYYY-MM/` with readable names.
- Facturas, invoices, recibos, receipts, Amazon order PDFs, CFDI XMLs, and RFC-named PDFs go to `~/Documents/Facturas/YYYY-MM/`.
- SAT acuses and constancias go to `~/Documents/SAT/YYYY-MM/`.
- Every move is logged in `~/.local/state/weekly-cleanup.log`.
- Preview a run without moving anything: `weekly-cleanup.sh --dry-run`

## 2. Daily work summary: `daily-summary.sh` + `mr-blockers.py`
Runs on weekdays at 12:30 (`daily-summary.timer`).

- Each run covers everything since the previous run (stored in `~/.local/state/daily-summary.last`).
- It saves to `~/Documents/daily-summaries/YYYY-MM-DD.md`.
- Sections: commits per repo (times, lines changed), uncommitted work, files touched, active time window, notes edited, and GitLab merge requests via `glab`.
- It ends with a standup message that is copied to the clipboard:
  - Done lists commits, or merge request activity when there were no commits.
  - In progress lists repos with uncommitted changes in files touched during the window.
  - Blockers come from `mr-blockers.py` and cover open, non-draft merge requests with a failed pipeline, conflicts, unresolved threads, or a needed rebase.
- Build a summary for a past day: `daily-summary.sh 2026-10-30`
- The previous version is saved as `daily-summary.sh.bak`.

## 3. Monthly invoice log: `monthly-invoices.py`
Runs on the 1st of each month at 10:00 (`monthly-invoices.timer`), right after the weekly cleanup.

- Reads last month's `~/Documents/Facturas/YYYY-MM/` and unzips any zip files there.
- CFDI XML gives issuer, RFC, receiver, subtotal, total, currency, and UUID.
- PDFs give total, RFC, and UUID via `pdftotext`.
- Income and expenses are split by your RFC (`PAMJ910503PH0`), and PDFs that duplicate an XML are flagged.
- Writes `YYYY-MM/log.csv` and adds to the running `~/Documents/Facturas/facturas-log.csv`.
- Rebuild a month: `monthly-invoices.py 2026-11`

## Managing timers
```
systemctl --user list-timers                          # next runs
systemctl --user start weekly-cleanup.service         # run one now
systemctl --user disable --now daily-summary.timer    # pause one
journalctl --user -u monthly-invoices.service         # see run output
```

## Git branch cleanup (`git-branch-cleanup.sh`, timer Mondays 9:15 with --apply)
Deletes local branches in `~/Code` and `~/Projects` whose last commit is older than 30 days, that have no branch on any remote, and that are already merged (reachable from HEAD or origin/HEAD). Skips the current branch, worktree branches, and main/master/develop/dev/staging/production/release*.
- Preview: `~/bin/git-branch-cleanup.sh`
- Delete: `~/bin/git-branch-cleanup.sh --apply` (options: `--days N`, `--root DIR`, `--include-unmerged`)
- Log of deleted branches with full SHAs: `~/.local/state/git-branch-cleanup.log`
- Restore one: `git -C <repo> branch <name> <sha>`
- Timer: `git-branch-cleanup.timer` (Mondays 9:15). Pause: `systemctl --user disable --now git-branch-cleanup.timer`. Run logs: `journalctl --user -u git-branch-cleanup`
