# pi coding agent setup

This repo tracks pi configuration under `config/.pi/`. Bootstrap/chezmoi links it into `~/.pi/`.

## What is versioned

| Path in repo | Home path | Purpose |
|---|---|---|
| `config/.pi/agent/settings.json` | `~/.pi/agent/settings.json` | Packages and defaults |
| `config/.pi/agent/extensions/` | `~/.pi/agent/extensions/` | Custom extensions (e.g. Omarchy theme sync) |
| `config/.pi/agent/prompts/` | `~/.pi/agent/prompts/` | Prompt templates |
| `config/.pi/agent/skills/` | `~/.pi/agent/skills/` | Agent skills (auto-loaded by pi) |

Pi loads skills from `~/.pi/agent/skills/` by default — no `skills` entry needed in `settings.json`.

## What is NOT versioned

- `~/.pi/agent/sessions/` — local chat history
- `~/.pi/agent/auth.json` — credentials (use `/login` on each machine)
- `~/.pi/agent/npm/` — installed npm packages (restored from `settings.json`)
- `enabledModels`, `lastChangelogVersion` — UI state; intentionally omitted

## New machine

### 1. Install pi

```bash
cd ~/Code/dotfiles
scripts/install-pi
```

### 2. Apply dotfiles

```bash
cd ~/Code/dotfiles
just import    # first time: register with chezmoi
just apply     # or: just sync / scripts/bootstrap
```

This links `config/.pi/` → `~/.pi/` (settings, extensions, prompts, skills).

### 3. Authenticate

Start pi and run `/login` for your provider (e.g. cursor). Auth stays local.

### 4. Verify

```bash
pi --version
ls ~/.pi/agent/settings.json ~/.pi/agent/extensions/omarchy-system-theme.ts
ls ~/.pi/agent/skills/ddev-workflow/SKILL.md
```

On first run, pi installs packages listed in `settings.json` automatically.

## Daily workflow

After `git pull`:

```bash
just sync
```

Edit pi config in the repo (`config/.pi/...`), not directly in `~/.pi/` unless adopting with `just adopt`.

## Optional skills

Work skills in this repo: `ddev-workflow`, `laravel-php`, `omarchy`.

Other skills (e.g. `migration-agent`, `review-agent`, `algo-sensei`) can live under `~/.pi/agent/skills/` — install or clone them on each machine as needed.
