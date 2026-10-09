# Platform admin (Super Admin)

The Super Admin controls platform-wide behaviour **from data, not code**. The app and the AI gateway read this config at runtime, so a change takes effect without a release.

## Who is a Super Admin
- Table `platform_admins (user_id uuid primary key references auth.users on delete cascade, created_at timestamptz default now())`.
- `is_platform_admin()`: a security definer function. It returns true when `auth.uid()` is in `platform_admins`.
- Bootstrapping the first admin is a one-off step in the Supabase SQL editor:
  `insert into platform_admins select id from auth.users where email = '<your login email>';`

## Config: `platform_config`
`platform_config (key text primary key, value jsonb not null, updated_at timestamptz, updated_by uuid)`.
- Anyone, anon included, reads it through the RPC `get_platform_config() → jsonb`, which returns `{key: value, …}`.
- Only admins write it, through `admin_set_config(p_key text, p_value jsonb)`. Every write is validated and audited in `platform_audit`.

Seeded keys and their defaults:

| key | value shape (defaults) |
|---|---|
| `features` | `{"ai":true,"ai_meal_draft":true,"ai_bazar_scan":true,"receipts":true,"notices":true,"duty":true,"reminders":true,"export":true,"recurring":true,"split":true,"fixed_rate":true,"google_login":true,"email_login":true}` |
| `ai` | `{"enabled":true,"primary_model":"gemini-flash-latest","fallback_model":"openrouter/free","quota_meal_draft":30,"quota_bazar_draft":10}` |
| `app` | `{"maintenance":false,"maintenance_message_bn":"","maintenance_message_en":"","min_version":"1.0.0","latest_version":"1.0.0","update_message_bn":"","update_message_en":"","support_email":"","support_whatsapp":"","privacy_url":"","banner":{"active":false,"text_bn":"","text_en":"","level":"info"}}` (level is info, warning or critical) |
| `defaults` | `{"month_start_day":1,"meal_off_cutoff":"22:00","meal_types":[{"name":"সকাল","weight":0.5,"enabled":false},{"name":"দুপুর","weight":1,"enabled":true},{"name":"রাত","weight":1,"enabled":true}],"expense_categories":[{"name":"বিদ্যুৎ","split":"equal"},{"name":"গ্যাস","split":"equal"},{"name":"ওয়াইফাই","split":"equal"},{"name":"পানি","split":"equal"},{"name":"বাসা ভাড়া","split":"equal"},{"name":"বুয়া","split":"equal"},{"name":"পরিষ্কার","split":"equal"},{"name":"মেরামত","split":"equal"},{"name":"অন্যান্য","split":"equal"}]}`. New messes are seeded from this. |
| `catalogue` | `{"groups":[{"name":"চাল-ডাল-তেল","items":[{"name":"চাল","unit":"কেজি"},…]},…]}`, the bazar item picker (seed it from the app's current `bazar_catalogue.dart`) |
| `payment_methods` | `[{"key":"cash","label_bn":"নগদ","label_en":"Cash","enabled":true},{"key":"bkash",…},{"key":"nagad",…},{"key":"bank",…},{"key":"other",…}]`. The keys must match the `pay_method` enum, and only labels and visibility can change. |

## Suspension
- `messes.suspended_at timestamptz`, `messes.suspended_reason text`; `profiles.suspended_at`, `profiles.suspended_reason`.
- A suspended mess is **read-only**: write policies and RPCs refuse with `MESS_SUSPENDED`, and reads still work. A suspended user is refused writes everywhere with `USER_SUSPENDED`.

## Admin RPCs (security definer; each checks `is_platform_admin()`, else raises `NOT_PLATFORM_ADMIN`)
- `admin_stats() → jsonb`: users_total, users_7d, messes_total, messes_active_7d (any write in the last 7 days), meals_7d, bazars_7d, ai_calls_7d, suspended_messes, deletion_pending.
- `admin_list_messes(p_search text, p_limit int, p_offset int)`: id, name, created_at, member_count, manager_names, last_activity, suspended_at.
- `admin_list_users(p_search text, p_limit int, p_offset int)`: id, email, full_name, created_at, last_sign_in_at, mess_count, suspended_at, is_admin.
- `admin_set_mess_suspended(p_mess uuid, p_suspended bool, p_reason text)` and `admin_set_user_suspended(p_user uuid, p_suspended bool, p_reason text)`
- `admin_set_admin(p_email text, p_is_admin bool)`. An admin can't remove themselves if they are the last one.
- `admin_ai_usage(p_days int)`: day, feature, calls.
- `admin_deletion_queue()`: user_id, requested_at, processed_at, last_error.
- Every admin write is logged in `platform_audit (id, actor_id, action, target, old jsonb, new jsonb, reason, at)`.

## Consumers
- **Mobile app:** `platformConfigProvider`, cached locally for offline use. Feature flags hide features. Maintenance mode shows a full-screen notice. When the app is below `min_version` it shows a soft update prompt; it blocks only in maintenance mode. A platform banner appears on Home. The bazar catalogue, the payment-method labels and the support contact all come from config.
- **AI gateway:** reads `ai` and `features` (cached for 60 s). These override the env defaults, and the `AI_ENABLED=false` env kill switch still wins.
- **Admin web panel:** a Flutter web entrypoint `app/lib/admin/admin_main.dart`, built with `flutter build web -t lib/admin/admin_main.dart` and deployed to Vercel as static files.

## Additions (v2 of this contract)

### Branding: config key `branding`
`{"app_name_bn":"মিল বাজার","app_name_en":"Meal Bazar","tagline_bn":"মেসের পুরো হিসাব, ফোন থেকেই","tagline_en":"Your whole mess, from your phone","logo_url":null,"accent_light":"#C98A0B","accent_dark":"#E8B33A"}`
- `logo_url` points to a file in the **public** Storage bucket `branding`. Only platform admins may upload there; everyone may read. When it is null, the app uses the bundled ম mark.
- The app uses the name, tagline and logo on the sign-in screen and the About/Account screen, and the accent colours from the theme's `accent` token. The colours must be valid `#RRGGBB` and contrast-checked in the admin UI.
- The **launcher icon and the home-screen app name cannot change without a new release**, which is an Android limitation. The admin UI says so.

### Feature flags: the full list in `features` (all default true)
`ai, ai_meal_draft, ai_bazar_scan, receipts, notices, duty, reminders, export, recurring, split, fixed_rate, google_login, email_login, member_meal_off, guest_meals, member_deposits, deposit_verification, dashboard_charts, pdf_report, share_bills, due_reminders, cook_share, bazar_picker, meal_defaults, audit_log, offline_mode, setup_checklist, invite_qr, push`.
`push` (0019) stops all push queueing in the DB and hides the push settings and the due-reminder button in the app.
A flag that is false hides every entry point of that feature in the app. The data and code stay in place. Unknown keys are ignored, and a missing key counts as true.

### Platform credentials (write-only)
- Table `platform_secrets (name text primary key, value text not null, updated_at timestamptz, updated_by uuid)`. RLS is enabled and **has no policies**, and all privileges are revoked from anon and authenticated, so only `service_role` can read it.
- Allowed names: `GEMINI_API_KEY`, `OPENROUTER_API_KEY`, `SMS_PROVIDER_KEY`, `SMTP_PASSWORD`, `PUSH_GATEWAY_URL` (the gateway base URL, e.g. `https://<project>.vercel.app`) and `PUSH_DISPATCH_SECRET` (a long random string; the gateway checks the header against it, with its `PUSH_DISPATCH_SECRET` env var as the fallback). The list is checked in the RPC. The DB reads the two push values itself to poke `/api/push/dispatch` (see DATABASE.md, Push).
- `admin_set_secret(p_name text, p_value text)` is admin-only and security definer. Passing null or '' deletes the secret. It is audited, with the value never logged.
- `admin_list_secrets()` is admin-only and returns name, `last4`, updated_at and updated_by. **It never returns values.**
- `get_platform_secrets()` returns jsonb and is **granted to service_role only**. The AI gateway calls it with the service-role key and caches the result for 60 s. A key stored in the DB beats the env var, and the env var stays as the fallback.

### Dynamic AI settings (v3)
The `ai` config key gets its final shape. Older flat fields are still read as a fallback:
```json
{
  "enabled": true,
  "text_chain":   [{"provider":"gemini","model":"gemini-flash-latest"},{"provider":"openrouter","model":"openrouter/free"}],
  "vision_chain": [{"provider":"gemini","model":"gemini-flash-latest"},{"provider":"openrouter","model":"openrouter/free"}],
  "quota_meal_draft": 30, "quota_bazar_draft": 10,
  "timeout_ms": 20000, "temperature": 0.2,
  "allow_paid": false
}
```
- Each feature walks its chain in order: meal drafts use `text_chain` and receipt scans use `vision_chain`. Providers are `gemini` and `openrouter`, and a chain holds 1 to 5 entries.
- When `allow_paid` is false, the gateway skips any OpenRouter model whose prompt or completion price is above 0, so paid models can't be used by accident.

Gateway admin endpoints. Each needs a Supabase JWT whose user passes `is_platform_admin()`, otherwise it returns 403:
- `GET /api/admin/models?provider=gemini|openrouter|all`: the model list, fetched live from the providers with the platform-stored or env keys and cached for 10 minutes. Each entry is normalised to `{provider, id, name, description, context_length, input_price_per_mtok, output_price_per_mtok, free: bool, vision: bool, text: bool}`.
  - OpenRouter: `GET https://openrouter.ai/api/v1/models`. A model is free when both prices are 0, and vision means `image` is in its input modalities.
  - Gemini: `GET https://generativelanguage.googleapis.com/v1beta/models?key=…`. Only models that support `generateContent` are kept. Free tier is assumed and the price is unknown (null). Vision is true for gemini 1.5 and later, flash and pro models.
- `POST /api/admin/test-model {provider, model, kind: "text"|"vision"}` runs a tiny fixed prompt (a 1×1 image for vision) and returns `{ok, latency_ms, sample, error}`. It does not count against any mess quota.

The admin panel's AI page has:
- provider tabs or an All view
- search
- filters for free, paid, vision, minimum context and price
- a sortable table
- "add to text chain" and "add to vision chain" actions
- drag to reorder each chain, and a Test button for every row and chain entry
- allow_paid, quota, timeout and temperature fields
- a warning before a paid model is saved while `allow_paid` is false
