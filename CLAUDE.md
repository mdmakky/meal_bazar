# Meal Bazar — agent guide

Bangla-first, offline-first mess management app for Bangladesh.
Vision: **"Run your whole mess from your phone in 2 minutes a day, in Bangla."**

## Source of truth (in order)
1. REQUIREMENTS.md 2. PRODUCT_RULES.md 3. ARCHITECTURE.md 4. DATABASE.md
5. DESIGN_SYSTEM.md 6. AI.md 7. Plan.md (original brief — **never edit**; never edit the .docx)

## Stack (do not change without strong reason)
- `app/` — Flutter, Riverpod, go_router, Drift, supabase_flutter, flutter_localizations (bn default, en), fl_chart, pdf/printing, share_plus, FCM.
- `supabase/` — Postgres migrations, RLS, SQL views/functions (the calculation engine), SQL tests.
- `ai-gateway/` — Vercel serverless functions only: `/api/ai/*` + cron. Gemini → OpenRouter → "AI unavailable".
- No Docker, no Next.js, no separate traditional backend.

## Hard rules
- **SQL = truth, AI = explanation.** Money/meal math lives in Postgres views/functions only. Never recompute balances in Dart or in an LLM.
- **AI drafts, human confirms.** AI never writes meals/money/bazar/deposits/expenses. Drafts are validated against a schema, shown for review, then saved by the user.
- **RLS is the security boundary.** Every mess-scoped table has RLS via `is_mess_member()` / `has_mess_role()`. Flutter-side checks are UX only.
- Money = `numeric(12,2)`. No floats for money.
- Closed months are immutable; override = explicit action + reason + audit log.
- No secrets in the Flutter app (only Supabase URL + anon key via `--dart-define`).
- Widgets never call Supabase directly: widget → provider → repository.
- Every screen: loading, empty, error (+retry) states. Use shared widgets in `app/lib/core/widgets/`.
- Client generates UUID primary keys → writes are idempotent upserts (offline sync safe).
- Design work goes through the `/impeccable:impeccable` skill; tokens live in `app/lib/core/theme/`.

## Commands
```sh
cd app && dart format . && flutter analyze && flutter test   # Flutter gate
./supabase/tests/run.sh                                          # SQL + RLS tests (local Postgres)
```
Every phase must pass the full gate before moving on. See DEVELOPMENT.md for setup and roadmap.
