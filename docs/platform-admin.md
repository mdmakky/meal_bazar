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
