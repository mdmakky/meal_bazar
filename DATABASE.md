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
| `expense_categories` | `mess_id`, `name`, `default_split` (meal/equal), `sort_order` |
| `expenses` | `mess_id`, `date`, `category_id`, `amount`, `split`, `paid_by_member_id`, `note`, `receipt_path` |
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
`ai_usage` (mess_id, day, feature, count), `ai_drafts` (status draft/confirmed/rejected), `announcements`, `notifications`, `meal_off_requests` (folded into `meal_entries.is_off` plus the cutoff check), `price_observations` (v1.2).

## Error codes
RPCs and triggers raise `errcode 'P0001'` with a short message key that the app maps to bn/en text: `MONTH_CLOSED`, `LAST_MANAGER`, `INVALID_INVITE`, `ALREADY_MEMBER`, `NOT_MANAGER`, `REASON_REQUIRED`.

## Storage
The `receipts` bucket is private. Object paths are `{mess_id}/{uuid}.jpg`. Policies: read if `is_mess_member(split_part(name,'/',1)::uuid)`, write if the caller is a manager (v1.1: the uploading member as well).
