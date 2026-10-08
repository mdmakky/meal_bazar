# Meal Bazar AI gateway

Vercel serverless functions (plain TypeScript, no framework). Contract: [`../AI.md`](../AI.md).
AI only drafts; the app shows the draft and the user saves it through the normal path.

## Deploy
1. Apply `supabase/migrations/0005_ai.sql` (table `ai_usage`, RPCs `ai_consume`, `ai_meal_context`).
2. `vercel link` with this folder as the project root, set the env vars below, `vercel deploy --prod`.
3. The cron in `vercel.json` hits `/api/cron/daily` at 03:00 UTC. Vercel sends `Authorization: Bearer $CRON_SECRET`.

Local checks: `npm install && npx tsc --noEmit && npx vitest run` (tests make no network calls).

## Env
| Var | Purpose |
|-|-|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | AI endpoints call Supabase **as the user** (their JWT), so RLS applies. |
| `SUPABASE_SERVICE_ROLE_KEY` | Used only by the keep-alive cron. |
| `GEMINI_API_KEY`, `OPENROUTER_API_KEY` | Providers. A missing key skips that provider. |
| `AI_PRIMARY_MODEL` | Gemini model. Default `gemini-flash-latest`, Google's alias for the current Flash model, which is on the free tier ([pricing](https://ai.google.dev/gemini-api/docs/pricing)). |
| `AI_FALLBACK_MODEL` | OpenRouter model. Default `openrouter/free`, OpenRouter's free-models router, which takes text and images ([link](https://openrouter.ai/openrouter/free)). Pin a specific `:free` vision model if you need stable output. |
| `AI_ENABLED` | `false` turns off all AI calls (`{unavailable:true, reason:'disabled'}`). |
| `CRON_SECRET` | Protects `/api/cron/daily`. |

## Endpoints
All take `Authorization: Bearer <supabase access token>`.
They return `200 {draft}` or `200 {unavailable:true, reason:'disabled'|'quota'|'providers'}`, or `4xx/5xx {error:code}`
(`unauthorized`, `forbidden`, `bad_request`, `bad_json`, `too_large`, `misconfigured`, `database`, `internal`).

- `POST /api/ai/meal-draft` `{mess_id, date, text}` → `{draft:{entries:[{member_id, meal_type_id, count, guest_count, is_off}], unmatched:[string], confidence}}`. Quota 30/mess/day.
- `POST /api/ai/bazar-draft` `{mess_id, date, image_base64}` (JPEG, at most about 400 KB) → `{draft:{items:[{name, qty, unit, price}], total, total_matches_items, notes}}`. Quota 10/mess/day. `total_matches_items` is computed by the gateway.
- `GET /api/cron/daily`: keep-alive.

Flow: bearer check → validate body → `ai_consume` (active member, `messes.ai_settings.enabled`, daily quota in Asia/Dhaka time) → prompt → Gemini (20 s) → OpenRouter (20 s) on any error, timeout, invalid JSON or schema failure → zod validation.

## Privacy
- Members are sent as refs `M1, M2…` plus their display name as an alias. Meal types are sent as `T1…` plus their name. No ids, phone numbers or money figures are sent. The gateway maps refs back to ids.
- The text or photo the user provides goes to Google or OpenRouter, whose free tiers may train on it. The app's AI settings screen must say so.
- Nothing is stored except the usage counter. User text, images and model replies are never logged. Only the provider name and the error status are logged.
- The model never writes SQL or data. It returns JSON, which is validated and returned as a draft.
