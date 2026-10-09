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
| `meal_types` | `mess_id`, `name`, `sort_order`, `weight numeric(4,2)`, `enabled` |
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
`ai_usage` (mess_id, day, feature, count), `ai_drafts` (status draft/confirmed/rejected), `notifications`, `meal_off_requests` (folded into `meal_entries.is_off` plus the cutoff check), `price_observations` (v1.2).

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
| `platform_secrets` | Write-only credentials (`GEMINI_API_KEY`, `OPENROUTER_API_KEY`, `SMS_PROVIDER_KEY`, `SMTP_PASSWORD`). No grants to anon/authenticated; `get_platform_secrets() → jsonb` is service_role only. |
| `branding` bucket | Public read, admin-only insert/update/delete. |

Admin RPCs (security definer; `NOT_PLATFORM_ADMIN` otherwise): `admin_stats()`, `admin_list_messes(search, limit, offset)`, `admin_list_users(search, limit, offset)`, `admin_set_config(key, value)` (`UNKNOWN_CONFIG_KEY`, `INVALID_CONFIG`), `admin_set_mess_suspended(mess, bool, reason)`, `admin_set_user_suspended(user, bool, reason)` (`REASON_REQUIRED` when suspending, `NOT_FOUND`), `admin_set_admin(email, bool)` (`USER_NOT_FOUND`, `LAST_ADMIN`), `admin_ai_usage(days)`, `admin_deletion_queue()`, `admin_set_secret(name, value)` (null/'' deletes; `INVALID_SECRET_NAME`; value never logged), `admin_list_secrets()` (name, last4, updated_at, updated_by).

## Error codes
RPCs and triggers raise `errcode 'P0001'` with a short message key that the app maps to bn/en text: `MONTH_CLOSED`, `LAST_MANAGER`, `INVALID_INVITE`, `ALREADY_MEMBER`, `NOT_MANAGER`, `REASON_REQUIRED`, `MESS_SUSPENDED`, `USER_SUSPENDED`, `NOT_PLATFORM_ADMIN`, `LAST_ADMIN`, `INVALID_CONFIG`.

## Storage
The `receipts` bucket is private. Object paths are `{mess_id}/{uuid}.jpg`. Policies: read if `is_mess_member(split_part(name,'/',1)::uuid)`, write if the caller is a manager (v1.1: the uploading member as well).
