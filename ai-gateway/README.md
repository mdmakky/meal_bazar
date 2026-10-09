# Meal Bazar AI gateway

Vercel serverless functions (plain TypeScript, no framework). Contract: [`../AI.md`](../AI.md).
AI only drafts; the app shows the draft and the user saves it through the normal path.

## Deploy
1. Apply `supabase/migrations/0005_ai.sql` (table `ai_usage`, RPCs `ai_consume`, `ai_meal_context`) and `0010_deletion_processed.sql` (deletion queue columns for the cron).
2. `vercel link` with this folder as the project root, set the env vars below, `vercel deploy --prod`.
3. The cron in `vercel.json` hits `/api/cron/daily` at 03:00 UTC. Vercel sends `Authorization: Bearer $CRON_SECRET`.

Local checks: `npm install && npx tsc --noEmit && npx vitest run` (tests make no network calls).

## Env
| Var | Purpose |
|-|-|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | AI endpoints call Supabase **as the user** (their JWT), so RLS applies. |
| `SUPABASE_SERVICE_ROLE_KEY` | Used by the daily cron (keep-alive + auth user deletion) and to read provider keys via `get_platform_secrets()`. |
| `GEMINI_API_KEY`, `OPENROUTER_API_KEY` | Providers, fallback for the keys stored in `platform_secrets`. A missing key skips that provider. |
| `AI_PRIMARY_MODEL` | Gemini model. Default `gemini-flash-latest`, Google's alias for the current Flash model, which is on the free tier ([pricing](https://ai.google.dev/gemini-api/docs/pricing)). |
| `AI_FALLBACK_MODEL` | OpenRouter model. Default `openrouter/free`, OpenRouter's free-models router, which takes text and images ([link](https://openrouter.ai/openrouter/free)). Pin a specific `:free` vision model if you need stable output. |
| `AI_ENABLED` | `false` turns off all AI calls (`{unavailable:true, reason:'disabled'}`), whatever the platform config says. |

## Settings precedence
The Super Admin changes AI behaviour from data ([`../docs/platform-admin.md`](../docs/platform-admin.md)); `lib/platform.ts` reads it.
- **Config:** `get_platform_config()` with the anon key (it is public), cached in memory for 60 s per instance. Keys used: `features.ai`, `features.ai_meal_draft`, `features.ai_bazar_scan` and `ai.*`.
- **Secrets:** `get_platform_secrets()` with the service-role key, cached for 60 s. Never logged.
- If an RPC fails or returns a malformed value, the last good value is used; if there is none, env and the built-in defaults are used. Failures aren't cached. Only the error kind is logged, never config values or keys.

| Setting | Order (first match wins) |
|-|-|
| AI on/off | `AI_ENABLED=false` env (no config fetch) → `ai.enabled && features.ai` → on. Each endpoint also needs `features.ai_meal_draft` / `features.ai_bazar_scan`. Then the mess's own `ai_settings.enabled` (in `ai_consume`). Off → `200 {unavailable:true, reason:'disabled'}`. |
| Provider chain | `ai.text_chain` (meal draft) / `ai.vision_chain` (bazar scan), 1–5 `{provider: gemini\|openrouter, model}` → `[gemini ai.primary_model, openrouter ai.fallback_model]` → `AI_PRIMARY_MODEL` / `AI_FALLBACK_MODEL` → `gemini-flash-latest` / `openrouter/free` |
| Timeout, temperature | `ai.timeout_ms` (1000–60000), `ai.temperature` (0–2) → 20000 ms, 0 |
| Paid models | `ai.allow_paid` → false. While false, OpenRouter chain entries are skipped unless their listed prompt and completion prices are both 0; ids ending `:free` and `openrouter/free` count as free; unknown pricing counts as paid. |
| Quotas (per mess per day) | `ai.quota_meal_draft` / `ai.quota_bazar_draft` → 30 / 10 |
| API keys | `platform_secrets` (`GEMINI_API_KEY`, `OPENROUTER_API_KEY`) → env |

Missing keys count as defaults; unknown keys are ignored. An invalid config (e.g. a 6-entry chain) is rejected as a whole and the fallback rules apply.
| `CRON_SECRET` | Protects `/api/cron/daily`. |

## Endpoints
All take `Authorization: Bearer <supabase access token>`.
They return `200 {draft}` or `200 {unavailable:true, reason:'disabled'|'quota'|'providers'}`, or `4xx/5xx {error:code}`
(`unauthorized`, `forbidden`, `bad_request`, `bad_json`, `too_large`, `misconfigured`, `database`, `internal`).

- `POST /api/ai/meal-draft` `{mess_id, date, text}` → `{draft:{entries:[{member_id, meal_type_id, count, guest_count, is_off}], unmatched:[string], confidence}}`. Quota 30/mess/day.
- `POST /api/ai/bazar-draft` `{mess_id, date, image_base64}` (JPEG, at most about 400 KB) → `{draft:{items:[{name, qty, unit, price}], total, total_matches_items, notes}}`. Quota 10/mess/day. `total_matches_items` is computed by the gateway.
- `GET /api/cron/daily` (`Authorization: Bearer $CRON_SECRET`) → `{kept_alive:true, deleted, failed}`. See Cron.

Admin endpoints (Bearer JWT whose user passes `is_platform_admin()`, else `403 {error:'forbidden'}`):
- `GET /api/admin/models?provider=gemini|openrouter|all` → `{models:[{provider, id, name, description, context_length, input_price_per_mtok, output_price_per_mtok, free, vision, text}]}`. Fetched live, cached 10 min per provider; `502 {error:'upstream'}` if a provider list fails. Gemini needs a key (none → empty list) and keeps only `generateContent` models; it's assumed free with unknown (null) prices.
- `POST /api/admin/test-model {provider, model, kind:'text'|'vision'}` → `{ok, latency_ms, sample, error}`. A fixed tiny prompt (a 1×1 PNG for vision), the configured timeout and temperature, no mess quota, `allow_paid` not applied. With `AI_ENABLED=false` it returns `{ok:false, error:'disabled'}`.

Flow: bearer check → validate body → platform settings → `ai_consume` (active member, `messes.ai_settings.enabled`, daily quota in Asia/Dhaka time) → prompt → each chain entry in order (default Gemini then OpenRouter, 20 s each), moving on at any error, timeout, invalid JSON or schema failure → zod validation.

## Cron
`/api/cron/daily` runs once a day with the service-role client:
1. Keep-alive: one trivial query so the free Supabase project is not paused.
2. Account deletion: takes up to 50 unprocessed `deletion_requests` (queued by `delete_my_account()`), never-tried rows first, oldest first, and calls `auth.admin.deleteUser` five at a time. Success, or "user not found", sets `processed_at`. A failure stores the error code in `last_error` and `last_attempt_at`, so the row goes to the back of the queue and is retried on the next run. Processed rows stay as the audit trail (user id + requested/processed times only; the profile is already anonymised).

Only the counts are logged, never user ids. A backlog over 50 drains at 50 per day.

## Privacy
- Members are sent as refs `M1, M2…` plus their display name as an alias. Meal types are sent as `T1…` plus their name. No ids, phone numbers or money figures are sent. The gateway maps refs back to ids.
- The text or photo the user provides goes to Google or OpenRouter, whose free tiers may train on it. The app's AI settings screen must say so.
- Nothing is stored except the usage counter. User text, images and model replies are never logged. Only the provider name and the error status are logged.
- The model never writes SQL or data. It returns JSON, which is validated and returned as a draft.
