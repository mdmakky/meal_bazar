# Database

The database is Supabase Postgres. Migrations live in `supabase/migrations/NNNN_name.sql` and tests in `supabase/tests/`.
Conventions:
- `id uuid primary key`. The client generates it (`gen_random_uuid()` is the default), which makes upserts idempotent.
- `created_at` and `updated_at timestamptz`.
- `deleted_at timestamptz` for soft delete on business rows.
- Money is `numeric(12,2) check (>= 0)`.
- Every mess-scoped table carries `mess_id` and has an index on it.

## RLS pattern
```sql
-- security definer helpers (avoid recursive RLS on mess_members)
is_mess_member(mess_id)          -- caller has an active/inactive membership (not 'left')
has_mess_role(mess_id, 'manager')
```
Every mess-scoped table:
```sql
alter table t enable row level security;
create policy t_read  on t for select using (is_mess_member(mess_id));
create policy t_write on t for all    using (has_mess_role(mess_id,'manager'))
                                       with check (has_mess_role(mess_id,'manager'));
```
Exceptions are noted per table. Multi-row or privileged operations run as `security definer` RPCs that check roles themselves.

## Tables

### Phase 1 — core
| Table | Key columns | Notes |
|---|---|---|
| `profiles` | `id` (= auth.users.id), `full_name`, `phone`, `avatar_path`, `locale`, `deleted_at` | A user reads their own profile and the profiles of people who share a mess with them. A user writes only their own. |
| `messes` | `name`, `address`, `month_start_day` 1–28, `currency` '৳', `meal_off_cutoff` time, `ai_settings` jsonb, `created_by` | Members read it, managers update it. Inserts go through the `create_mess()` RPC only. |
| `mess_members` | `mess_id`, `user_id`, `display_name`, `role` (manager/member), `status` (active/inactive/left/pending), `joined_on`, `left_on`, `room`, `notes` | Unique on `(mess_id, user_id)`. A member can see the other members of their own messes. Writes are manager-only. The last-manager guard is a trigger. |
| `mess_invites` | `mess_id`, `code` (6 chars, unique), `expires_at`, `created_by`, `revoked_at` | Managers only. Joining goes through the `join_mess(code)` RPC, which creates a `pending` membership. |
| `audit_log` | `mess_id`, `actor_id`, `action`, `entity`, `entity_id`, `old` jsonb, `new` jsonb, `source` (app/ai/system), `reason`, `at` | Insert only, written by triggers and RPCs. Members can read it. Nobody can update or delete it. |

RPCs: `create_mess(name, month_start_day) → mess_id`, `join_mess(code) → member_id`, `approve_member(member_id)`, `set_member_role(member_id, role)`, `set_member_status(member_id, status)`.

### Phase 2 — meals
| Table | Columns |
|---|---|
| `meal_types` | `mess_id`, `name`, `sort_order`, `weight numeric(4,2)`, `enabled`, `serve_time time` (0024) |
| `meal_entries` | `mess_id`, `member_id`, `date`, `meal_type_id`, `count numeric(3,1)` (check: a multiple of 0.5 between 0 and 5), `guest_count smallint` 0–20, `is_off`, `updated_by`. Unique on `(member_id, date, meal_type_id)`. |

### Phase 3 — money
| Table | Columns |
|---|---|
| `bazars` | `mess_id`, `date`, `buyer_member_id`, `amount`, `paid_by_member_id` (null = mess fund), `note`, `receipt_path`, `source` |
| `bazar_items` | `bazar_id`, `name`, `qty numeric(10,3)`, `unit`, `price` |
| `bazar_buyers` (0018) | `bazar_id`, `mess_id`, `member_id`; pk `(bazar_id, member_id)`. Who went to the bazar (several allowed). Informational only: no money math reads it; the credit still goes to the single `paid_by_member_id`. Write all at once with `set_bazar_buyers(bazar_id, uuid[])` (manager; `NOT_FOUND` / `NOT_MANAGER` / `NOT_MEMBER`), which also keeps `bazars.buyer_member_id` = the first buyer for older clients. Backfilled from `buyer_member_id`. Closed-month guard via the parent bazar's date. |
| `expense_categories` | `mess_id`, `name`, `default_split` (meal/equal), `sort_order` |
| `expenses` | `mess_id`, `date`, `category_id`, `amount`, `split`, `paid_by_member_id`, `note`, `receipt_path` |
| `expense_shares` (0012) | `expense_id`, `mess_id`, `member_id`, `weight numeric(6,2)` (default 1). When an equal-split expense has rows here, only those members pay, in proportion to weight. Write all at once with `set_expense_shares(expense_id, jsonb)`. The closed-month guard uses the parent expense's date. |
| `deposits` | `mess_id`, `member_id`, `date`, `amount`, `method` (cash/bkash/nagad/bank/other), `trx_id`, `status` (verified/pending/rejected), `screenshot_path` |

### Phase 4 — months (the calculation engine)
| Object | Purpose |
|---|---|
| `months` table | `mess_id`, `start_date`, `end_date` (exclusive), `status` (open/closed), `closed_at`, `closed_by`. Unique on `(mess_id, start_date)`. |
| `month_member_summary` table | The snapshot written at close: `month_id`, `member_id`, `meals`, `food_cost`, `extra_cost`, `credit`, `opening_balance`, `closing_balance` |
| `month_totals(month_id)` fn | `food_total`, `total_meals`, `meal_rate`, `extra_total` |
| `member_balances(month_id)` fn | One row per member with every column from PRODUCT_RULES §3. Live for open months, read from the snapshot for closed months. |
| `close_month(month_id)` / `reopen_month(month_id, reason)` | PRODUCT_RULES §4 |
| `guard_closed_month` trigger | On meal_entries, bazars, expenses and deposits: raises `MONTH_CLOSED` when the row's date falls inside a closed month |

### Later
`ai_usage` (mess_id, day, feature, count), `ai_drafts` (status draft/confirmed/rejected), `meal_off_requests` (folded into `meal_entries.is_off` plus the cutoff check), `price_observations` (v1.2).

### Bazar duty (0014)
`bazar_duties (mess_id, date, member_id, note, done)`, unique on `(mess_id, date, member_id)`, hard-deleted. Members read, managers write. `mark_my_duty_done(id, done default true)` lets the assigned member tick their own row (`NOT_YOUR_DUTY` otherwise). `generate_duty_rotation(mess, from, days, member_ids[], every default 1)` (manager) assigns members round-robin on `from, from+every, …` within `days`, skipping dates that already have a duty (`INVALID_ROTATION` for bad input).

### Account deletion (0007)
`delete_my_account()` RPC: refuses with `LAST_MANAGER` while the caller is the only manager of a mess that other app users still belong to. Otherwise pending requests are deleted, memberships become `left` and are unlinked (`user_id = null`, `display_name` kept), a mess with no other app users is soft-deleted, the profile is anonymised ("Former member", no phone/photo, `deleted_at`), and the user is queued in `deletion_requests (user_id, requested_at)`. Postgres cannot remove the Supabase auth user, so the gateway's daily cron (service role) calls `auth.admin.deleteUser` for each queued row and sets `processed_at` (0010); failures record `last_error` and retry next day. The app signs out after the RPC.

### Notices (0013)
`announcements` (title ≤ 80, body ≤ 1000, `pinned`, nullable `expires_at`, soft delete) and `announcement_reads` (`announcement_id`, `member_id`, `read_at`; pk both). Members read, managers write (audited). A member may insert/upsert only their own read rows (`is_own_notice_read`). The `announcement_feed` view hides deleted and expired notices and adds the caller's `is_read`.

### Recurring bills and meal defaults (0015)
| Object | Purpose |
|---|---|
| `recurring_expenses` table | `mess_id`, `category_id`, `amount`, `split`, `note`, `active`, `day_of_period` 1–28, `created_by`. Standard RLS. |
| `recurring_applied` table | `(recurring_id, period_start)` primary key, `mess_id`: marks a template as posted for a billing period. Standard RLS. |
| `apply_recurring_expenses(mess, date) → int` | Manager. Posts each active, not-yet-posted template as an expense in the period containing `date`. Idempotent; refused with `MONTH_CLOSED` in a closed month. |
| `pending_recurring_count(mess, date) → int` | Active templates not yet posted in that period. |
| `meal_defaults` table | `(member_id, meal_type_id)` primary key, `mess_id`, `count numeric(3,1)` 0–5 in ½ steps. Standard RLS. `fill_meals_for_day` uses yesterday, else this, else 1. |

### Fixed meal rate (0016)
`messes.meal_rate_mode` ('calculated'/'fixed', default calculated), `messes.fixed_meal_rate numeric(12,2)` (> 0, required when fixed), `months.fixed_meal_rate` (per-month override). `month_totals.meal_rate` returns the fixed rate when one is in force, so `member_balances`/`close_month` follow. `month_rate_info(mess, from, to)` → `mode, rate, calculated_rate, food_total, total_meals, surplus_or_deficit` (= food_total − rate × total_meals). `set_month_meal_rate(mess, date, rate|null)` (manager; `MONTH_CLOSED` in a closed month).

### Platform admin (0017)
Contract: `docs/platform-admin.md`. **Bootstrap the first admin once** in the Supabase SQL editor:
`insert into platform_admins select id from auth.users where email = '<your login email>';`
| Object | Purpose |
|---|---|
| `platform_admins`, `is_platform_admin()` | Who is a Super Admin. RLS on, no policies. `is_platform_admin()` is callable by authenticated (the gateway uses it). |
| `platform_config` + `get_platform_config() → jsonb` | Keys `features`, `ai`, `app`, `defaults`, `catalogue`, `payment_methods`, `branding`. Readable by anon/authenticated via the RPC only. `platform_config_defaults()` holds the seed and the fallback. |
| `platform_audit` | Every admin write (`actor_id, action, target, old, new, reason, at`). Admins read. |
| suspension | `messes.suspended_at/suspended_reason`, `profiles.suspended_at/suspended_reason`. A `*_suspension` trigger on every mess-scoped business table (plus `messes`, `profiles`) calls `assert_mess_writable(mess_id)`: `USER_SUSPENDED` / `MESS_SUSPENDED` on writes; reads still work. Admins and `delete_my_account()` are exempt. Only admins can change the suspension columns. |
| new messes | `seed_mess_defaults`, `seed_expense_categories` and `create_mess` (month start when not passed, meal-off cutoff) read `defaults`. |
| `platform_secrets` | Write-only credentials (`GEMINI_API_KEY`, `OPENROUTER_API_KEY`, `SMS_PROVIDER_KEY`, `SMTP_PASSWORD`, and from 0019 `PUSH_GATEWAY_URL`, `PUSH_DISPATCH_SECRET`). No grants to anon/authenticated; `get_platform_secrets() → jsonb` is service_role only. |
| `branding` bucket | Public read, admin-only insert/update/delete. |

Admin RPCs (security definer; `NOT_PLATFORM_ADMIN` otherwise): `admin_stats()`, `admin_list_messes(search, limit, offset)`, `admin_list_users(search, limit, offset)`, `admin_set_config(key, value)` (`UNKNOWN_CONFIG_KEY`, `INVALID_CONFIG`), `admin_set_mess_suspended(mess, bool, reason)`, `admin_set_user_suspended(user, bool, reason)` (`REASON_REQUIRED` when suspending, `NOT_FOUND`), `admin_set_admin(email, bool)` (`USER_NOT_FOUND`, `LAST_ADMIN`), `admin_ai_usage(days)`, `admin_deletion_queue()`, `admin_set_secret(name, value)` (null/'' deletes; `INVALID_SECRET_NAME`; value never logged), `admin_list_secrets()` (name, last4, updated_at, updated_by).

### Push (0019)
| Object | Purpose |
|---|---|
| `device_tokens` | `token` pk, `user_id` (auth user, cascade), `platform` android/ios/web, `updated_at`. RLS: a user reads/deletes only their own rows. Writes via `register_device_token(token, platform)` (upsert; a token registered to another account moves to the caller) and `unregister_device_token(token)` (own rows only). |
| `profiles.notification_prefs` | jsonb object, `{type: false}` turns a type off; a missing key is on. The user edits their own (profiles RLS). |
| `push_outbox` | `user_id, type, title, body` (already in the recipient's `profiles.locale`), `data {route, type}`, `created_at, claimed_at, sent_at, attempts, last_error`. No client access. |
| triggers (AFTER, security definer) | `join_request` (pending membership → active managers), `deposit_pending` (pending deposit → managers), `deposit_verified` / `deposit_rejected` (→ the member), `notice` and `bazar_added` (→ active members except the author), `expense_added` (one push per INSERT statement per mess, so a recurring batch is one push), `month_closed` (→ all active members). Recipients must have a device, the type on and no `deleted_at`; the actor is never notified. The platform flag `features.push = false` stops all queueing. Rejected writes (RLS, closed month, suspension) never reach the AFTER triggers. |
| `send_due_reminders(mess) → int` | Manager. Each other active app member whose `member_balances` closing balance for the current period (Dhaka date) is negative gets their own due amount. Returns how many were queued; audited as `send_due_reminders`; `TOO_SOON` within 10 minutes; `MESS_SUSPENDED` / `USER_SUSPENDED`. |
| `push_kick()` | Once per transaction, `net.http_post` (pg_net, sent after commit) to `PUSH_GATEWAY_URL/api/push/dispatch` with header `x-push-secret: PUSH_DISPATCH_SECRET`. A no-op without pg_net or either secret; a failure is a warning, never a failed write. |
| `push_claim(limit) → rows` | service_role. Claims up to `limit` unsent rows (under 5 attempts, under 3 days old; claims older than 2 minutes count as abandoned), increments `attempts`, returns them with the user's tokens. Deletes rows older than 30 days. |

`delete_my_account()` also deletes the caller's device tokens and queued pushes.

### Home v2 (0021)
All security invoker (members read the inputs under RLS; non-members get nothing).
| Function | Purpose |
|---|---|
| `manager_attention(mess, date)` | `pending_deposits` (any date), `pending_members`, `meals_missing` (active members present on `date` with no meal row that day; an *off* row counts as entered), `pending_recurring`. |
| `mess_cash(mess, from, to)` | `deposits_in` (verified) − `fund_spent` (bazar + expenses with `paid_by_member_id` null) = `cash`. Own-pocket payments never touch it; `pending_deposits` is reported, never counted. |
| `member_transparency(mess, from, to)` | Per member: verified `deposits`, `own_pocket` (bazar + expenses they paid), `closing_balance` (from `member_balances`). Due first. |
| `my_activity(mess, limit = 30)` | `audit_log` rows by others that concern the caller, newest first, limit 1–100: meal changes (updates/deletes, plus inserts with an off or a guest, so the daily fill is not noise), deposits, bazar paid/went (`bazar_buyers`), expenses paid/shared (`expense_shares`). Adds `ref_type` (meal/deposit/bazar/expense), `ref_id`, `actor_id`, `actor_name`. |

### Messages (0022)
Member ↔ manager messages (not real-time chat) and "report a problem" about an entry. A thread is between one member and all of the mess's managers.
| Object | Purpose |
|---|---|
| `message_threads` | `mess_id`, `member_id` (the member side), `subject` ≤ 80, `ref_type` (deposit/bazar/expense/meal/other, nullable), `ref_id`, `ref_label` ≤ 120, `status` open/resolved, `created_by`, `last_message_at`. Read by the thread's member and the mess's active managers (`can_see_thread`); nobody else. No client write policies. Suspension trigger. |
| `messages` | `thread_id`, `mess_id`, `sender_id` (auth user, null after account deletion), `body` 1–1000. Append-only: read like its thread, no update/delete for anyone. Suspension trigger. |
| `message_reads` | `(thread_id, user_id)` pk, `read_at`. Each user reads only their own rows; written by `mark_thread_read`. |
| `message_thread_feed` view | My visible threads + `member_name`, `last_body`, `last_sender_id`, `is_unread` (a message from someone else after my last read). |
| `start_thread(p_id, p_mess, p_subject, p_body, p_ref_type, p_ref_id, p_ref_label, p_member, p_message_id) → uuid` | A member opens a thread as themselves; a manager may pass `p_member`. Idempotent on `p_id`. `NOT_MANAGER` / `NOT_MEMBER`. |
| `post_message(p_id, p_thread, p_body)` | A participant appends (idempotent on `p_id`); the member writing into a resolved thread reopens it. `NOT_MEMBER` for a thread I can't see. |
| `set_thread_status(p_thread, p_status)` | Managers resolve/reopen; the member may only reopen (`NOT_MANAGER`). |
| `mark_thread_read(p_thread)`, `unread_thread_count(p_mess) → int` | My read mark; my unread threads in a mess. |
| push `message` | AFTER INSERT on `messages`: the member writes → every active manager; a manager writes → the member. Title `বার্তা: <subject>` / `Message: <subject>`, body `<sender>: <text>`, route `/more/messages/<thread_id>`. Off when the `push` or `messages` flag is false or the user's `message` pref is false. |

### Mess group (0023)
One group conversation per mess on the 0022 tables (not separate ones: the feed, read marks, `post_message`, push routing and the app's thread screen all apply unchanged).
| Object | Purpose |
|---|---|
| `message_threads.kind` | `direct` (default, 0022 behaviour) or `group`. A group has `member_id` null (check: group ⇔ no member); unique index: one group per mess. `can_see_thread(mess, null)` = the mess's managers and active/inactive members; pending, left and outsiders see nothing. |
| `ensure_mess_group(p_mess) → uuid` | Any current member; returns the group's thread id, creating it on first use (also while the mess is suspended: a system row). `NOT_MEMBER`. |
| `messages.hidden_at`, `hidden_by` | Soft delete. `hide_message(p_id)`: group messages only; managers any, a member their own; idempotent; otherwise `NOT_MANAGER` (direct-thread messages stay append-only). The text moves to `message_hidden_bodies` (no client access) and `body` becomes `''`; audited as `hide_message` with `{thread_id, sender_id}` (never the text). |
| `message_thread_feed` | + `kind`, `last_hidden`; `member_name` null for the group. Hidden messages are never unread. |
| `unread_thread_count(mess)` | Now direct threads only ("needs attention"); the app counts group unread from the feed. |
| `push_enqueue(…, p_route, p_tag)` | 8-argument form; `p_tag` lands in `data.tag` (the gateway sets the Android notification tag, so a newer push with the same tag replaces the older). The 7-argument form delegates with no tag. |
| push `group_message` | AFTER INSERT on a group message → every other active member. Title `<mess> · গ্রুপ` / `<mess> · group`, body `<sender>: <first 80 chars>`, route `/more/messages/<thread_id>`, tag = thread id. Off when `push`, `messages` or `mess_group` is false, or the user's `group_message` pref is false (the in-app "mute group"). |

### Meal-off deadline (0024)
| Object | Purpose |
|---|---|
| `messes.meal_off_lead_minutes` | int 0–2880, nullable. How long before a meal's `serve_time` a member may still switch it. Null (default, all messes) = the old rule: previous day at `meal_off_cutoff`. |
| `meal_types.serve_time` | `time not null`, Asia/Dhaka. Backfilled and filled on insert from the name (`default_serve_time`: সকাল 08:00, দুপুর 13:30, রাত 21:00, else 13:00). Manager-edited like the rest of the row. |
| `meal_off_deadline(p_mess, p_date, p_meal_type) → timestamptz` | `(date + serve_time) at time zone 'Asia/Dhaka' − lead`, or `(date − 1 + meal_off_cutoff)` with no lead. Security invoker (null for a mess I can't read). |
| `meal_off_deadlines(p_mess, p_from, p_to) → (date, meal_type_id, deadline)` | The same for every meal type and day (≤ 32 days); the app shows these. |
| `set_my_meal_off(p_mess, p_date, p_meal_type, p_off)` | Own row only, active members. `FEATURE_OFF` when the `member_meal_off` flag is false, `MEAL_TYPE_INVALID`, `CUTOFF_PASSED` from the deadline on (managers skip both the flag and the deadline). Closed-month and suspension triggers still apply. A real change (off ↔ on) calls `post_meal_off_notice`. |
| `messages.kind`, `messages.meta` | `user` (default) or `system`. A system message's `meta` is `{t: 'meal_off', member, name, date, meal, meal_name, off}`; `body` is the bn text without the name (`আজ রাতের মিল বন্ধ করেছেন`; day word আজ/কাল/গতকাল or `DD/MM` in Bangla digits). The app renders it as a centred pill per viewer locale. |
| `post_meal_off_notice(…)` | Server-only (no client execute). Posts the notice into the mess group (`ensure_mess_group`) as the member; deletes the member's notice for the same (date, meal) from the last 2 minutes first (flip-flop collapse; the new insert re-pushes with the group tag, replacing the old push). Skipped when `messages` or `mess_group` is false. Push follows `group_message`. |

### Member bazar, inbox, month close (0026)
| Object | Purpose |
|---|---|
| `bazar_requests` | A member's own bazar awaiting the manager: `id` (client uuid), `member_id` (submitter), `date`, `amount > 0`, `own_pocket` (true → the approved bazar's `paid_by_member_id` is the submitter; false → mess fund), `buyer_ids uuid[]` (submitter first, then companions), `items jsonb` (`[{name, qty, unit, price}]`), `note`, `receipt_path`, `status` pending/approved/rejected/cancelled, `reject_reason`, `bazar_id`, `reviewed_by/at`. Read: the submitter and managers. No direct writes. No money math reads it. |
| `submit_bazar_request(p_mess, p_id, p_date, p_amount, p_own_pocket, p_buyer_ids, p_items, p_note, p_receipt_path) → uuid` | Active members. Idempotent on `p_id`. `FUTURE_DATE`, `MONTH_CLOSED`, `FEATURE_OFF` (flag `member_bazar`), `RECEIPT_PATH_INVALID`, `ITEMS_INVALID`, `MONTH_NOT_ENDED`, `MISSING_MEALS`, `AUTO_MEALS_PENDING`. Unknown/inactive buyers are dropped. Push `bazar_request` → managers. |
| `cancel_bazar_request(p_id)` | The submitter, while pending; else `BAZAR_REQUEST_NOT_PENDING`. |
| `review_bazar_request(p_id, p_approve, p_reason?) → uuid` | Manager. Approve: inserts the bazar with **the request's id**, its items (blank names skipped) and buyers, all guards and audit apply; returns the bazar id. Reject: stores the reason, returns null. Push `bazar_request_reviewed` → submitter (who is skipped by the generic `bazar_added`). `BAZAR_REQUEST_NOT_PENDING`. |
| `notifications` | Per-user inbox: `id bigint`, `type`, `title`, `body` (in the user's locale), `route`, `created_at`, `read_at`. Every `push_enqueue` writes it for all recipients (device or not, push pref or not) except `message`/`group_message`; rows older than 60 days are pruned. Read own only. |
| `mark_notifications_read(p_ids bigint[] = null)` / `unread_notification_count() → int` | null = all. |
| push `deposit_added` | A manager inserts a verified deposit for another member → that member. |
| `month_pending_items(p_mess, p_from, p_to) → (pending_deposits, pending_bazar_requests)` | Members. `close_month` fails `PENDING_ITEMS` while either is > 0 in the period. |
| `my_last_month(p_mess) → (start_date, end_date, status, closed_at, meals, food_cost, extra_cost, credit, opening_balance, closing_balance)` | The period before today's (Dhaka). Money columns are the caller's closed snapshot, null while open. No row when that period has no meals/bazar and no months row. |
| `manager_attention` | Adds `pending_bazar_requests`. |

### Auto meals (0031)
| Object | Purpose |
|---|---|
| `messes.auto_meals` | boolean, default false; managers switch it in More → Default meals. `auto_meals_last_date` / `auto_meals_last_count` record the last run that created rows. |
| `meal_entries.source = 'auto'` | Rows made by the job. Not audited on insert. Any app edit sends `source = 'app'`, so only untouched rows keep the tag (the grid shows a dot on them). |
| `auto_fill_meals(p_days = 3, p_today = Dhaka today)` | Service role only (Vercel cron `/api/cron/midnight`, 18:00 UTC = 00:00 Dhaka). For each mess with `auto_meals`, not suspended, for each of the last `p_days` (max 7) days before `p_today`: skips closed months; inserts the missing (member × enabled meal type) rows `on conflict do nothing`, so an existing row (including meal-off) is never touched. Eligible: `joined_on <= day` and (`active`, or `left` with `left_on > day`); inactive and pending are skipped. Count = the member's `meal_defaults` row, else 1. A per-(mess, day) `pg_try_advisory_xact_lock` makes concurrent runs skip, and a repeat run creates nothing. Each day is its own sub-transaction and is **verified** cell by cell against `auto_meal_eligible(mess, day)`; the result is stored in `auto_meal_runs(mess_id, date, status ok/incomplete/failed, eligible, created, error, attempts)`. Returns rows created. |
| `messes.auto_meals_since` | Set by trigger when the switch turns on (Dhaka date), null when off. Month close only requires the job for days on/after it. |

### Month lifecycle (0032)
| Object | Purpose |
|---|---|
| `dhaka_today()` | Today in Asia/Dhaka; a session GUC `meal_bazar.today` may pin it (SQL tests only — no API can set a GUC). |
| `months` snapshot columns | `food_total, total_meals, meal_rate, extra_total, credit_total` stored at close; `closed_missing` (missing member-days the manager confirmed); `reopened_at`, `reopen_reason` (set while a month is reopened = "correcting"); `totals_reconstructed` (true when the totals were backfilled from current data by the migration, not frozen at close). Unique partial index `(mess_id, end_date) where status='closed'`: one closed month per end date, so a balance can only be carried forward once. |
| `month_totals_live` / `member_balances_live` | The 0016 / 0012 bodies, renamed. Used by `close_month` to compute the snapshot. |
| `month_totals` / `member_balances` | Wrappers: for a closed month return the stored totals and `month_member_summary` exactly; otherwise live. For an open period whose previous period is not closed (never closed, or reopened) and earlier activity exists, `opening = previous period's closing` (recursively resolved), `closing = live closing + that opening`. One number crosses the boundary, so deposits, bazars and expenses are never counted twice; closing the previous month later replaces it with the frozen figure. `opening_is_provisional(mess, from)` tells which case applies. |
| `month_missing_meals(mess, from, to)` | (day, member_id, display_name): present member (active, or left after that day) with **no entry of any kind** on a day of the ended part of the period. Same rule as `manager_attention.meals_missing`. |
| `month_review(mess)` | One row: the oldest ended period not closed (else the latest ended): status open/correcting/closed, stored or live totals, pending deposits/requests, missing member-days, `auto_state` (off/ok/pending/incomplete/failed for the last day), `auto_bad_days`, `totals_reconstructed`, `opening_provisional`, `can_close`. Powers the Month-End Review and the status chip. |
| `close_month(mess, date, confirm_missing = false)` | One close at a time per mess (advisory lock). Refuses: `NOT_MANAGER`, `MONTH_CLOSED`, `PREVIOUS_MONTH_OPEN`, `MONTH_NOT_ENDED`, `PENDING_ITEMS`, `AUTO_MEALS_PENDING` (job enabled for the last day but its `auto_meal_runs` status is not `ok`), `MISSING_MEALS` (unless `confirm_missing`, then the count is stored and audited). Never creates entries. Snapshots totals and per-member rows once. |
| `reopen_month(month, reason)` | Reason ≥ 5 chars, audited, sets `reopened_at/reopen_reason`, pushes `month_reopened` to the other members. Closing again clears them and re-snapshots. |
| `my_last_month(mess)` | Adds `provisional` and `reopened_at`; while the month is not closed the figures are provisional, never null. |

## Error codes
RPCs and triggers raise `errcode 'P0001'` with a short message key that the app maps to bn/en text: `MONTH_CLOSED`, `LAST_MANAGER`, `INVALID_INVITE`, `ALREADY_MEMBER`, `NOT_MANAGER`, `REASON_REQUIRED`, `MESS_SUSPENDED`, `USER_SUSPENDED`, `NOT_PLATFORM_ADMIN`, `LAST_ADMIN`, `INVALID_CONFIG`, `TOO_SOON`, `CUTOFF_PASSED`, `FEATURE_OFF`, `PENDING_ITEMS`, `FUTURE_DATE`, `BAZAR_REQUEST_NOT_PENDING`, `ITEMS_INVALID`.

## Storage
The `receipts` bucket is private. Object paths are `{mess_id}/{uuid}.jpg`. Policies: read if `is_mess_member(split_part(name,'/',1)::uuid)`, write if the caller is a manager (v1.1: the uploading member as well).
