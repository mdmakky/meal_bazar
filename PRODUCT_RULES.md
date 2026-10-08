# Product Rules

These are the business rules. The SQL implementation is in `supabase/migrations`, and each rule here has a test in `supabase/tests`. If code and this file disagree, fix one of them. Never leave them divergent.

## 1. Meals
- A **meal type** has a `name`, a `sort_order`, an `enabled` flag and a `weight` (default 1.00, allowed range 0–5). Example: Breakfast 0.5, Lunch 1, Dinner 1.
- A **meal entry** is one row per (member, date, meal type) and holds:
  - `count`: the member's own meals. Allowed values are 0, 0.5, 1, 1.5 … 5 (steps of 0.5). Default 1 when the row is created by "fill today".
  - `guest_count`: a whole number from 0 to 20. Guests are charged to this member (the host).
  - `is_off`: the member switched this meal off. When it is true, `count` is forced to 0, and guests still count.
- **No row means 0 meals.** The Today screen offers "Fill today", which creates rows from yesterday (or from the default of 1) for active members.
- **Billable meals** for an entry = `(count + guest_count) × meal_type.weight`.
- Disabling a meal type hides it from new entry. Its historical rows still count.
- **Meal-off cutoff** (v1.1): a member may set `is_off` for a (date, meal type) only before `mess.meal_off_cutoff`, which is a time on the previous day (default 22:00 Asia/Dhaka). After the cutoff only a manager can change the meal.

## 2. Money
- Every amount is `numeric(12,2)` and at least 0. Currency is shown as ৳.
- **Bazar** (a grocery purchase) is always a *food* cost.
- **Expense** has a category and a `split`:
  - `meal`: added to the food cost (it affects the meal rate). Example: cooking gas, if the mess wants that.
  - `equal`: split equally among the members **present on the expense date**.
    Or among **selected members** only, each with a weight (`ভাগ`, default 1): a member pays amount × weight / Σ weights.
- **Who paid** (bazar and expense): `paid_by_member_id` is either null or set.
  - null means it was paid from the mess fund, and nobody gets a credit.
  - set means the member paid from their own pocket. The amount becomes a **credit** to that member, the same way a deposit is.
- **Deposit**: money a member gives to the mess fund. It is a credit to that member. In v1.1, a deposit a member records themselves is `pending` and does not count until a manager verifies it.
- A member is **present on date d** when `joined_on ≤ d` and (`left_on` is null or `d < left_on`). The *inactive* status only hides the member from the meal grid. It does not affect money.

## 3. Calculation (one source of truth: SQL)
For one mess month `[start, end)`:
```
food_total        = Σ bazar.amount + Σ expense.amount where split = 'meal'
total_meals       = Σ billable meals of all members
meal_rate         = food_total / total_meals          (0 if total_meals = 0; unrounded internally)
member_meals      = Σ billable meals of the member
member_food_cost  = round(member_meals × meal_rate, 2)
member_extra_cost = Σ over equal-split expenses: round(amount / present_members_on_date, 2)
                    (an expense shared among selected members: round(amount × weight / Σ weights, 2) for each selected member only)
member_credit     = Σ verified deposits + Σ own-pocket bazar/expense paid by member
opening_balance   = previous closed month's closing_balance (0 for the first month)
closing_balance   = opening_balance + member_credit − member_food_cost − member_extra_cost
```
- A positive balance is an **advance**. A negative balance is a **due**.
- The meal rate is shown rounded to 2 decimals. Members' costs are computed from the unrounded rate and then rounded, so the rounded shares can differ from the total by a few paisa. This is accepted, and the report shows the difference as "rounding".
- If `total_meals = 0` while `food_total > 0`, the month summary shows a warning and nobody is charged until meals exist.
- Worked example (the test fixture): Lunch weight 1, Dinner weight 1. Rahim has 10 meals plus 2 guest meals, Karim has 8.5. Bazar is ৳1,410. Total meals = 20.5, so the rate is ৳68.78…, Rahim's cost is ৳825.37 and Karim's is ৳584.63. WiFi ৳500 on an equal split gives each ৳250.00. Rahim deposited ৳1,500, so his balance is +৳424.63 (advance).

## 4. Months
- A mess has a `month_start_day` from 1 to 28 (default 1). Month *n* runs from that day up to the same day of the next month.
- A **month** is a row with status `open` or `closed`. Only one open month at a time is the "current" month, and earlier months may be closed.
- **Close month** (manager only): computes every member's figures, stores them as a `month_member_summary` snapshot, and sets the status to `closed`. The next month's opening balance comes from this snapshot.
- **Closed months are immutable.** A database trigger rejects any insert, update or delete of meals, bazar, expenses or deposits dated inside a closed month.
- **Override** = `reopen_month(month_id, reason)`. The reason is required and must be at least 5 characters. Only a manager can do it, and it writes an audit row. While the month is reopened, edits are allowed again, and the month must then be closed again. Reopening month *n* while month *n+1* is closed is refused: reopen the later months first.

## 5. Members and history
- Leaving sets `status = left` and `left_on`. All the member's rows stay and keep counting in their months.
- Account deletion anonymises the profile (name becomes "Former member", phone and photo are removed). Mess financial rows are kept.
- A mess must always have at least one active manager. The last manager cannot leave or be demoted.

## 6. Roles (v1)
| Action | Manager | Member |
|---|---|---|
| Read the mess's data (meals, bazar, expenses, deposits, summaries) | ✓ | ✓ |
| Write meals for anyone; write bazar, expenses and deposits | ✓ | — |
| Switch own meal off before the cutoff (v1.1) | ✓ | ✓ |
| Record own deposit as pending (v1.1) | ✓ | ✓ |
| Members, roles, settings, month close/reopen | ✓ | — |
| Edit own profile | ✓ | ✓ |

## 7. AI
- AI output is always a **draft**. Nothing reaches the database until a person taps Confirm, and the save then goes through the same validated path as manual entry, with `source = 'ai'` written to the audit log.
- AI never computes money. When it explains numbers, those numbers come from the SQL functions above.
