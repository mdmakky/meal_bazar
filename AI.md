# AI

**Rules:** AI drafts and a human confirms. SQL is the truth and AI only explains. The app is fully usable with AI turned off or unavailable.

## Gateway (`ai-gateway/`, Vercel)
```
Flutter ──POST /api/ai/<feature>  (Authorization: Bearer <supabase JWT>)──► gateway
gateway: verify JWT → check membership + role → check mess ai_settings + quota
       → build minimal prompt → Gemini → (on 429/5xx/timeout/invalid JSON) OpenRouter
       → validate output against JSON schema (zod) → log ai_usage + audit(source='ai')
       → 200 {draft} | 200 {unavailable:true, reason} | 4xx
```
- The gateway is plain TypeScript serverless functions with no framework. Its dependencies are `zod` and `@supabase/supabase-js` only. Providers are called with `fetch`.
- Model IDs and the provider order come from environment variables (`AI_PRIMARY_MODEL`, `AI_FALLBACK_MODEL`), so they can change without a deploy of app code. Re-check the current free-tier model names in Phase 6.
- Each provider call has a timeout of 20 s, there is at most one fallback, and the total stays under the function limit.
- **Quota:** the `ai_usage` table records (mess_id, day, feature). Defaults are 30 text calls and 10 vision calls per mess per day. When the quota is exceeded the gateway returns `{unavailable:true, reason:'quota'}`.
- **Cache:** explanation features (v1.1) are cached on `(feature, mess_id, hash(input))` for 24 h.
- **Kill switch:** the `AI_ENABLED=false` environment variable, or `messes.ai_settings.enabled=false`.

## Privacy
- The AI receives **the minimum context**. A meal draft gets the member list as pseudonyms plus aliases, and the meal-type names. A bill explanation gets the pre-computed numbers, never raw tables.
- **Pseudonymisation is on by default.** Names are sent as `M1, M2…` together with the nicknames the user typed, and the gateway maps them back. The raw text the user typed does go to the model, and the AI settings screen says so.
- Disclosure in the settings screen: "AI features send the text or photo you provide to Google Gemini / OpenRouter. The free tiers may use it to improve their models."
- Images are compressed before upload. Receipts are not stored by the gateway.

## MVP features

### 1. Quick meal entry — `POST /api/ai/meal-draft`
Input:
```json
{ "mess_id": "…", "date": "2026-10-08", "text": "aj Rahim 2, Karim off, rat e guest 1",
  "members": [{"ref":"M1","aliases":["Rahim","রহিম"]}, …],
  "meal_types": [{"ref":"T1","name":"Lunch"},{"ref":"T2","name":"Dinner"}] }
```
Output (validated):
```json
{ "entries": [ {"member":"M1","meal_type":"T1","count":2,"guest_count":0,"is_off":false} ],
  "unmatched": ["rat e guest 1 — whose guest?"], "confidence": 0.0-1.0 }
```
Validation rules: every `member` and `meal_type` must be a ref that was sent, `count` must be a multiple of 0.5 between 0 and 5, and `guest_count` must be a whole number from 0 to 20. Entries that fail are moved to `unmatched`.
The app shows the AI Draft sheet: one row per entry with Edit and Remove, the unmatched lines highlighted, and Confirm All. Confirm All writes through the normal meal repository with `source='ai'`.

### 2. Receipt / ফর্দ scan — `POST /api/ai/bazar-draft`
Input: one JPEG (at most 1280 px), `mess_id` and `date`. Output:
```json
{ "items":[{"name":"আলু","qty":2,"unit":"kg","price":60}], "total": 120, "total_matches_items": true, "notes": "" }
```
If the AI total does not match the sum of the items, the app shows both figures and the user picks one. The draft opens the normal Bazar form already filled in.

## Later features (whitelisted tools only)
Ask Your Mess (v1.2) runs tool calls against fixed, mess-scoped read-only functions. The LLM never writes SQL:
`get_month_totals(month)`, `get_member_balance(member, month)`, `get_meal_rate(month)`, `get_month_expenses(month, category?)`, `get_member_meal_count(member, month)`.
The gateway executes these with the **user's JWT**, not the service role, so RLS still applies.

## Audit
Every confirmed AI draft writes the business rows with `source='ai'`. Every gateway call writes `ai_usage`. Rejected drafts are not stored.
