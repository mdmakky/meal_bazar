# Architecture

```
┌────────────── Flutter app (app/) ──────────────┐
│ presentation  widgets/screens (no logic, no SQL)│
│      ↓ watch/read                               │
│ application   Riverpod providers / controllers  │
│      ↓                                          │
│ data          repositories                      │
│      ├── Drift (local DB) ←→ SyncQueue ─────────┼──► Supabase PostgREST / RPC  (RLS enforced)
│      └── direct reads of SQL views ─────────────┼──► Supabase (summaries, balances)
│ domain        plain Dart models + validators    │
└──────────────┬──────────────────────────────────┘
               │ HTTPS + Supabase JWT
               ▼
     Vercel ai-gateway/ (/api/ai/*, cron)  ──► Gemini → OpenRouter → "unavailable"
               │ service role (server only)
               ▼
           Supabase (quota, audit, read-only AI views)
```

## Responsibilities
| Layer | Owns | Never does |
|---|---|---|
| Postgres | Schema, constraints, RLS, **every calculation** (views/functions), month close, closed-month trigger, audit triggers | — |
| Flutter `data/` | Supabase and Drift access, mapping rows to models, the sync queue | Business math |
| Flutter `application/` | Riverpod providers: loading/error state, orchestration | Widgets, SQL |
| Flutter `domain/` | Immutable models, input validators (phone, amount, meal count) | I/O |
| Flutter `presentation/` | Screens and widgets from the design system | Supabase calls, calculations |
| Vercel `ai-gateway/` | Prompting, provider fallback, schema validation, quota, AI audit rows, sending queued pushes (FCM) | Writing business data (it returns drafts only) |

## Flutter layout
```
app/lib/
  main.dart                 bootstrap: env, Supabase init, ProviderScope
  app.dart                  MaterialApp.router, theme, localisation
  core/
    theme/                  tokens + ThemeData (DESIGN_SYSTEM.md)
    widgets/                AppButton, AppCard, AppSheet, StateViews, SyncBadge …
    l10n/                   arb files (bn default, en)
    router.dart             go_router + auth redirect
    env.dart                --dart-define values
    errors.dart             AppFailure + mapper (Postgrest/Auth/Socket → user message key)
    format.dart             ৳, Bangla digits, dates
  features/
    auth/      {data,application,presentation}
    mess/      …              (create, join, members, settings)
    meals/     …              (Phase 2)
    bazar/ expenses/ deposits/ month/ ai/ …
```
A feature gets a `domain/` folder only when it has models or validators of its own. There are no interfaces with only one implementation. Repositories are concrete classes injected through providers and overridden in tests.

## Offline-first (Phase 5)
- Meal and bazar writes go to Drift first, together with a `sync_queue` row (`id` = the row UUID, table, op, payload, attempts, status).
- A background worker drains the queue whenever the device is online, using `upsert` on the client-generated UUID, so a retry is idempotent and never duplicates a row.
- Conflicts are resolved by last write wins, compared on `updated_at`. The server's audit trigger keeps the overwritten value.
- The UI shows the state of every row and every screen: synced, syncing, offline or failed (with retry).
- Reads: the screens that matter (Today, the meal grid) read from Drift, which a pull refreshes. Summaries come from the SQL views and are cached locally for display while offline, marked as stale.

Phases 1–4 write straight to Supabase through repositories. Phase 5 adds Drift and the queue behind the **same repository API**, so the screens do not change.

## Security model
- Auth: Supabase phone OTP. The JWT is stored by supabase_flutter.
- Authorization: **RLS only** (see DATABASE.md). The app hides buttons for UX reasons, but the DB enforces the rules.
- Privileged multi-row operations (`create_mess`, `join_mess`, `close_month`) are `security definer` RPC functions that check the caller's role inside the function.
- Secrets: the APK contains only the Supabase URL and the anon key, passed through `--dart-define`. The Gemini key, the OpenRouter key and the service role key exist only in Vercel environment variables.
- Receipts are stored in a private Storage bucket under the path `mess/{mess_id}/…`. Storage RLS uses `is_mess_member`, and files are fetched through signed URLs.

## Free-tier notes
See REQUIREMENTS §6. In terms of architecture:
- Vercel is never in the hot path, so a Vercel outage only disables AI.
- A daily Vercel cron calls a cheap Supabase RPC, which keeps the free project from pausing, and also sends the day's reminders.
- Push: Postgres AFTER triggers queue `push_outbox` rows and poke the gateway through pg_net after commit; the gateway sends them with FCM HTTP v1. A Vercel or FCM outage only delays pushes (the daily cron retries); it never blocks a write.
- Images are compressed on the device (max 1280 px, JPEG quality 70) before they are uploaded or sent to the AI.
