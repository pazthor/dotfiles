---
name: ddev-workflow
description: Run commands and tests inside DDEV containers for the go-roam monorepo (apps/experiences-app Laravel backend, apps/experiences-app-client Svelte widget, apps/experiences-app-client-proxy Cloudflare Worker). Use when invoking php, artisan, composer, pest, npm, node, vite, wrangler, or any build/test command in the go-roam repo, or when the user mentions DDEV, the container, or any of the experiences-app apps.
---

# DDEV Workflow (go-roam monorepo)

## Core rule

The go-roam repo is bind-mounted into a DDEV container. **All executed commands run inside the container**, never on the host. File edits are made directly in the workspace (the bind mount makes them visible inside the container immediately).

## Command patterns

Use `ddev exec` for one-shot commands from the repo root:

```bash
ddev exec php artisan migrate
ddev exec composer test
ddev exec composer lint
```

For commands inside a sub-app, use `--dir`:

```bash
ddev exec --dir /var/www/html/apps/experiences-app-client npm run build
ddev exec --dir /var/www/html/apps/experiences-app-client-proxy npm run dev
```

Use `ddev ssh` when running an interactive sequence:

```bash
ddev ssh
cd apps/experiences-app-client
npm run dev
```

## Per-app conventions

- `apps/experiences-app/` (Laravel 12, PHP 8.3, Pest): `ddev exec composer test`, `ddev exec php artisan ...`, `ddev exec composer review`. Repo-root Make targets (`make test`, `make test-filter f=Name`) already wrap DDEV; prefer them when available.
- `apps/experiences-app-client/` (Svelte 5 + Vite): `ddev exec --dir /var/www/html/apps/experiences-app-client npm run build | test:run | test:e2e`. The dev server (`npm run dev`) is auto-started by pm2 on `ddev start` (`tools/apps.config.js`); check it with `ddev exec pm2 status` and tail logs with `ddev exec pm2 logs app-front --nostream`.
- `apps/experiences-app-client-proxy/` (Cloudflare Worker via Hono): pm2 also runs this as `proxy`; `ddev exec --dir /var/www/html/apps/experiences-app-client-proxy npm run deploy` for deploys.

## Hostnames and ports

- `https://experiences-app.ddev.site` — Laravel app + Filament admin (Filament is mounted at `/app`)
- `https://proxy.experiences-app.ddev.site` — proxy worker
- `https://app.experiences-app.ddev.site` — alternate FQDN

Vite dev server is exposed via DDEV `web_extra_exposed_ports` (container 5174 → host 5174 https / 5172 http). The actual vite port lives in `apps/experiences-app-client/vite.config.js` — verify the two match when host browser access to vite is needed.

## Database, mail, storage

- Postgres 14: `ddev exec php artisan migrate`, `ddev exec php artisan db:fresh --seed`, `make db/seed-experience`.
- Adminer: `https://experiences-app.ddev.site:9101`.
- Mailpit: `https://experiences-app.ddev.site:8026`.
- MinIO (S3-compatible): `https://experiences-app.ddev.site:9090`.

## Stripe

- Local webhook listener: `make stripe/listen` (wraps `ddev exec`).

## Anti-patterns

- Running `php`, `composer`, `artisan`, `npm`, `vite`, or `wrangler` directly on the host.
- `cd apps/... && npm ...` on the host instead of inside the container.
- Editing files via `ddev exec` — file edits go through normal workspace editing.
- Restarting `ddev` to "fix" a Vite/HMR issue — first check `ddev exec pm2 logs app-front --nostream`.

## Quick diagnostics

```bash
ddev describe                              # services, URLs, container ports
ddev exec pm2 status                       # vite + proxy dev processes
ddev exec pm2 logs app-front --nostream    # vite logs (HMR, build errors)
ddev exec pm2 logs proxy --nostream        # proxy worker logs
ddev exec php artisan about                # Laravel runtime info
```
