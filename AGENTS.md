# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:full hash:f65d5d33 -->
## Task Tracking

This is a **personal dotfiles repository**, so keep task tracking lightweight.

### Default approach

- Small tweaks, config edits, and one-off fixes do **not** need a formal issue.
- Track follow-up work in the final handoff message, or in project docs only when that documentation is genuinely useful.
- Avoid creating duplicate tracking systems for trivial work.

### Optional: bd (beads)

`bd` is **optional**, not required.
Use it only when the work is large enough to benefit from structured tracking, for example:

- multi-step migrations
- refactors spanning several files or tools
- blocked work with dependencies
- backlog items you want to revisit later

If `bd` is available and you choose to use it, prefer JSON output:

```bash
bd ready --json
bd create "Issue title" --description="Context" --json
bd update <id> --claim --json
bd close <id> --reason "Completed" --json
```

If `bd`/`dolt` is not installed or configured, continue without it.

### Important rules

- ✅ Prefer simple workflows for simple changes
- ✅ Use `bd` only when it adds real value
- ✅ Keep handoff notes clear when follow-up work remains
- ❌ Do NOT make `bd` a blocker for routine dotfile edits
- ❌ Do NOT require Dolt/beads setup just to change personal config

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is not complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **Run quality gates** (if code changed) - tests, linters, builds, or basic script validation
2. **Summarize remaining work** - mention any follow-up in the handoff
3. **PUSH TO REMOTE** - this is mandatory:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
4. **Verify** - all intended changes are committed and pushed
5. **Hand off** - provide concise context for the next session

**OPTIONAL when using bd:**

```bash
bd dolt push
```

Only run that if `bd` is configured and you actually used it during the session.

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

<!-- END BEADS INTEGRATION -->


## Build & Test

_Add your build and test commands here_

```bash
# Example:
# npm install
# npm test
```

## Architecture Overview

_Add a brief overview of your project architecture_

## Conventions & Patterns

_Add your project-specific conventions here_
