---
name: laravel-php
description: Laravel 12 and PHP 8.3+ development with service-layer architecture, Form Requests, API Resources, Pest tests, Filament admin, and DDEV container workflow. Use when writing or reviewing PHP/Laravel code, artisan commands, migrations, services, controllers, models, Filament resources, Pest tests, or when the user mentions Laravel, PHP, Eloquent, Filament, or backend work in the go-roam monorepo.
---

# Laravel & PHP (go-roam)

## First: DDEV

All backend commands run **inside DDEV**, never on the host. Before running `php`, `artisan`, `composer`, or Pest, load and follow [ddev-workflow](../ddev-workflow/SKILL.md).

Quick reference:

```bash
ddev exec php artisan migrate
ddev exec composer test          # Pest
ddev exec composer lint          # Pint
ddev exec composer review        # rectify + lint + test
make test                        # repo-root wrapper
make test-filter f=TestName
```

## Stack

- PHP 8.3+, Laravel 12, PostgreSQL 14, Pest, Filament 3
- Backend path: `apps/experiences-app/`
- Strict typing everywhere: `declare(strict_types=1);`

## Architecture

### Request flow

```
Route → Form Request (validation) → Controller (thin) → Service (logic) → Model/DB
                                                              ↓
                                                    API Resource (JSON response)
```

- **Controllers**: `final`, read-only, no property mutations. Use method injection, not constructor injection.
- **Services**: `final`, read-only. Business logic lives in `app/Services/`. Two patterns:
  - Invokable: single-action classes (e.g. `GetAllActiveExperiences`)
  - Orchestration: multi-step processes (e.g. `OrderService`, `RefundService`)
- **Models**: `final`. Use `$fillable` (never `$guarded = []`). Use `$casts` for non-string types.
- **DTOs/Value Objects**: Service methods accept typed DTOs, not associative arrays.
- **Jobs**: Dispatch slow work (emails, payments, backfills) — never block HTTP responses.

### Directory conventions

| Layer | Location |
|-------|----------|
| Services | `app/Services/{Domain}/` |
| Form Requests | `app/Http/Requests/` |
| API Resources | `app/Http/Resources/` |
| Filament | `app/Filament/Resources/` |
| Shared Filament behavior | `app/Filament/Traits/` |
| Settings (spatie) | `app/Settings/` |
| Tests | `tests/Feature/`, `tests/Unit/` |

Generate Filament resources with `php artisan make:filament-*`, never hand-roll.

## Code standards

### PHP

- PSR-12 (enforced by Pint)
- Explicit return types and parameter type hints on all methods
- PHP 8.3 features where appropriate: typed properties, `match`, readonly classes
- Reusable query constraints → Eloquent local scopes

### Laravel patterns

- Eloquent/Query Builder over raw SQL
- Form Requests for all input validation
- API Resources for all JSON responses
- Database transactions via `DB::transaction()` for multi-step writes
- Events + listeners for side effects (e.g. `OrderPlaced` → `SendOrderConfirmationEmail`)
- Policies/Sanctum for authorization
- Queues for background processing

### Anti-patterns

- Fat controllers with business logic
- `$guarded = []` on models
- Passing raw arrays into services
- Raw SQL when Eloquent suffices
- Backfills inside migrations (use queued jobs)
- Running artisan/composer/php on the host

## Testing (Pest)

All new code must have Pest tests.

```bash
ddev exec composer test
make test-filter f=describe_or_test_name
```

- Feature tests for HTTP endpoints and integration flows
- Unit tests for isolated service logic
- Use factories and existing test helpers; match surrounding test style
- Only add tests that cover real behavior — skip trivial assertions

## Migrations

For schema changes, also load [migration-agent](~/.claude/skills/migration-agent/SKILL.md) when available.

Key rules:
- Every migration must have a working `down()`
- Never combine schema change + dependent code in the same MR
- Backfill via queued jobs, not migrations
- Use expand/contract for renames and destructive changes

## Filament admin

- Resources in `app/Filament/Resources/`
- Extract shared table/filter/action behavior into traits under `app/Filament/Traits/`
- Settings pages: add property to Settings class → settings migration → form field on Filament page

## go-roam domain notes

- **Schedule** = `TimeSlot` model
- Custom-price bookings intentionally have `pricing_tier_id = null`
- Stripe Connect for multi-party payments; webhook handlers in `app/Services/Stripe/Webhooks/`
- Deferred payments: card saved at checkout, charged off-session later. **Not supported for Connect-hosted experiences** (422 at API + disabled in Filament)
- Email branding via `App\Settings\EmailSettings`; templates use MJML

## Implementation checklist

When adding a feature:

1. Read existing code in the same domain — match conventions
2. Form Request for validation
3. Service method with typed parameters/return
4. Thin controller delegating to service
5. API Resource for response shape
6. Pest tests (feature + unit as appropriate)
7. Run `ddev exec composer review` before finishing

## Related skills

- [ddev-workflow](../ddev-workflow/SKILL.md) — container commands, hostnames, diagnostics
- [migration-agent](~/.claude/skills/migration-agent/SKILL.md) — safe schema changes
- [review-agent](~/.claude/skills/review-agent/SKILL.md) — MR discipline
