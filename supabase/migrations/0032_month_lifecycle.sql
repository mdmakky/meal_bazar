-- 0032_month_lifecycle: month close you can review and trust.
--  * a month closes only after it has ended, with pending items resolved, the
--    automatic meal job finished for its last day, and missing meal entries
--    explicitly confirmed (recorded in the audit log, never silently filled);
--  * closed months are stable snapshots: member_balances / month_totals return
--    the stored figures, so changing meal weights, the rate mode or member
--    dates can never alter history;
--  * carry-forward happens once: at most one closed month may end on a date;
--  * reopening keeps its reason, notifies members and shows as "correcting".
-- Contract: DATABASE.md "Month lifecycle (0032)".

-- ── today, in one place (tests may pin it; no API can set a GUC) ─────────
create or replace function public.dhaka_today() returns date
language sql stable as $$
  select coalesce(nullif(current_setting('meal_bazar.today', true), '')::date,
                  (now() at time zone 'Asia/Dhaka')::date);
$$;

-- ── snapshot columns ─────────────────────────────────────────────────────
alter table public.months
  add column food_total     numeric,
  add column total_meals    numeric,
  add column meal_rate      numeric,
  add column extra_total    numeric,
  add column credit_total   numeric,
  add column closed_missing int not null default 0,   -- missing member-days confirmed at close
  add column totals_reconstructed boolean not null default false,  -- backfilled from current data, not frozen at close
  add column reopened_at    timestamptz,
  add column reopen_reason  text;

-- Two closed months ending on one date would carry a balance forward twice.
create unique index months_one_closed_per_end on public.months (mess_id, end_date)
  where status = 'closed';

-- Live figures keep their bodies under a new name; the public names become
-- wrappers that serve the snapshot for a closed month.
alter function public.month_totals(uuid, date, date) rename to month_totals_live;
alter function public.member_balances(uuid, date, date) rename to member_balances_live;

create or replace function public.month_totals(p_mess uuid, p_from date, p_to date)
returns table (food_total numeric, total_meals numeric, meal_rate numeric,
               extra_total numeric, credit_total numeric)
language sql stable set search_path = public as $$
  select mo.food_total, mo.total_meals, mo.meal_rate, mo.extra_total, mo.credit_total
  from months mo
  where mo.mess_id = p_mess and mo.status = 'closed' and mo.start_date = p_from
    and mo.end_date = p_to and mo.food_total is not null
  union all
  select * from month_totals_live(p_mess, p_from, p_to)
  where not exists (select 1 from months mo
                    where mo.mess_id = p_mess and mo.status = 'closed' and mo.start_date = p_from
                      and mo.end_date = p_to and mo.food_total is not null);
$$;

-- True when the opening balance of the period starting p_from is not a frozen
-- snapshot: no month is closed ending there, yet earlier activity exists.
create or replace function public.opening_is_provisional(p_mess uuid, p_from date) returns boolean
language sql stable set search_path = public as $$
  select not exists (select 1 from months mo where mo.mess_id = p_mess and mo.status = 'closed'
                     and mo.end_date = p_from and mo.food_total is not null)
     and (exists (select 1 from meal_entries where mess_id = p_mess and date < p_from)
          or exists (select 1 from bazars where mess_id = p_mess and deleted_at is null and date < p_from)
          or exists (select 1 from expenses where mess_id = p_mess and deleted_at is null and date < p_from)
          or exists (select 1 from deposits where mess_id = p_mess and deleted_at is null and date < p_from));
$$;

-- closing = opening + credit − food − extra (see 0012). Closed month: the
-- stored snapshot. Otherwise live, and where the previous month is not closed
-- the opening is that month's own (recursively resolved) closing balance, so
-- an unclosed or reopened month never makes the next one look debt-free. The
-- carried figure is a single number per member; the previous month's deposits
-- and bills stay in the previous month, so nothing is counted twice.
create or replace function public.member_balances(p_mess uuid, p_from date, p_to date)
returns table (member_id uuid, display_name text, status public.member_status,
               meals numeric, food_cost numeric, extra_cost numeric, credit numeric,
               opening_balance numeric, closing_balance numeric)
language sql stable set search_path = public as $$
  with snap as (
    select s.member_id, m.display_name, m.status, s.meals, s.food_cost, s.extra_cost, s.credit,
           s.opening_balance, s.closing_balance
    from month_member_summary s
    join months mo on mo.id = s.month_id
    join mess_members m on m.id = s.member_id
    where mo.mess_id = p_mess and mo.status = 'closed' and mo.start_date = p_from
      and mo.end_date = p_to and mo.food_total is not null
  ),
  live as (select * from member_balances_live(p_mess, p_from, p_to)),
  prov as (
    select b.member_id, b.closing_balance
    from (select * from month_period(p_mess, p_from - 1)
          where opening_is_provisional(p_mess, p_from)) pp,
         lateral member_balances(p_mess, pp.start_date, pp.end_date) b
  )
  select * from (
    select * from snap
    union all
    select coalesce(l.member_id, p.member_id), coalesce(l.display_name, m.display_name),
           coalesce(l.status, m.status),
           coalesce(l.meals, 0), coalesce(l.food_cost, 0), coalesce(l.extra_cost, 0), coalesce(l.credit, 0),
           coalesce(l.opening_balance, 0) + coalesce(p.closing_balance, 0),
           coalesce(l.closing_balance, 0) + coalesce(p.closing_balance, 0)
    from live l
    full join prov p on p.member_id = l.member_id
    left join mess_members m on m.id = coalesce(l.member_id, p.member_id)
    where not exists (select 1 from snap)
  ) x
  order by display_name;
$$;

-- Months closed before this migration: store the totals as they compute today
-- (the originals were never saved, so this is the best that exists).
alter table public.months disable trigger user;
update public.months mo
set (food_total, total_meals, meal_rate, extra_total, credit_total) =
      (select t.food_total, t.total_meals, t.meal_rate, t.extra_total, t.credit_total
       from public.month_totals_live(mo.mess_id, mo.start_date, mo.end_date) t),
    totals_reconstructed = true
where mo.status = 'closed' and mo.food_total is null;
alter table public.months enable trigger user;

-- ── missing meal entries ─────────────────────────────────────────────────
-- A present member (active, or left after that day) with no entry of any kind
-- (meal, off, zero or automatic) on a day of the period that has ended.
create or replace function public.month_missing_meals(p_mess uuid, p_from date, p_to date)
returns table (day date, member_id uuid, display_name text)
language sql stable set search_path = public as $$
  select d::date, m.id, m.display_name
  from generate_series(p_from, least(p_to - 1, dhaka_today() - 1), interval '1 day') d
  join mess_members m on m.mess_id = p_mess and m.status in ('active', 'left')
       and m.joined_on <= d::date and (m.left_on is null or m.left_on > d::date)
  where is_mess_member(p_mess)
    and exists (select 1 from meal_types t where t.mess_id = p_mess and t.enabled)
    and not exists (select 1 from meal_entries e where e.member_id = m.id and e.date = d::date)
  order by 1, 3;
$$;

-- ── the period waiting to be closed ──────────────────────────────────────
-- The oldest ended period that is not closed (months close in order); when
-- all are closed, the latest ended one. No row for a mess whose first
-- activity is still in the current period.
create or replace function public.month_review(p_mess uuid)
returns table (start_date date, end_date date, status text, closed_at timestamptz,
               reopened_at timestamptz, closed_missing int,
               food_total numeric, total_meals numeric, meal_rate numeric,
               extra_total numeric, credit_total numeric,
               pending_deposits int, pending_bazar_requests int, missing_days int,
               auto_state text, auto_bad_days int, totals_reconstructed boolean,
               opening_provisional boolean, can_close boolean)
language plpgsql stable set search_path = public as $$
declare
  v_today date := dhaka_today();
  v_first date;
  d       date;
  ps      date;
  pe      date;
  lps     date;
  lpe     date;
  v_found boolean := false;
  i       int := 0;
  mo      months%rowtype;
  t       record;
  v_dep   int;
  v_req   int;
  v_miss  int;
  v_auto  text;
  v_bad   int;
begin
  if not is_mess_member(p_mess) then
    return;
  end if;
  select min(x) into v_first from (
    select min(date) x from meal_entries where mess_id = p_mess
    union all select min(date) from bazars where mess_id = p_mess and deleted_at is null
    union all select min(date) from expenses where mess_id = p_mess and deleted_at is null
    union all select min(date) from deposits where mess_id = p_mess and deleted_at is null) a;
  if v_first is null then
    return;
  end if;
  d := v_first;
  loop
    select p.start_date, p.end_date into ps, pe from month_period(p_mess, d) p;
    exit when pe > v_today or i > 240;
    i := i + 1;
    lps := ps; lpe := pe;
    if not month_is_closed(p_mess, ps) then
      v_found := true;
      exit;
    end if;
    d := pe;
  end loop;
  if not v_found then
    if lps is null then
      return;
    end if;
    ps := lps; pe := lpe;
  end if;

  select * into mo from months m where m.mess_id = p_mess and m.start_date = ps;
  select * into t from month_totals(p_mess, ps, pe);
  select pi.pending_deposits, pi.pending_bazar_requests into v_dep, v_req
  from month_pending_items(p_mess, ps, pe) pi;
  select count(*)::int into v_miss from month_missing_meals(p_mess, ps, pe);
  -- 'off' = the job was not meant to cover the last day; else that day's status.
  select case when coalesce(ms.auto_meals and ms.auto_meals_since <= pe - 1, false)
              then coalesce((select r.status from auto_meal_runs r
                             where r.mess_id = p_mess and r.date = pe - 1), 'pending')
              else 'off' end
  into v_auto from messes ms where ms.id = p_mess;
  select count(*)::int into v_bad from auto_meal_runs r
  where r.mess_id = p_mess and r.date >= ps and r.date < pe and r.status <> 'ok';

  return query select ps, pe,
    case when mo.status = 'closed' then 'closed'
         when mo.reopened_at is not null then 'correcting' else 'open' end,
    mo.closed_at, mo.reopened_at, coalesce(mo.closed_missing, 0),
    t.food_total, t.total_meals, t.meal_rate, t.extra_total, t.credit_total,
    coalesce(v_dep, 0), coalesce(v_req, 0), coalesce(v_miss, 0), coalesce(v_auto, 'off'),
    coalesce(v_bad, 0), coalesce(mo.totals_reconstructed, false), opening_is_provisional(p_mess, ps),
    coalesce(mo.status, 'open') <> 'closed' and coalesce(v_dep, 0) + coalesce(v_req, 0) = 0
      and coalesce(v_auto, 'off') in ('off', 'ok');
end $$;

-- ── close ────────────────────────────────────────────────────────────────
drop function public.close_month(uuid, date);
create function public.close_month(p_mess uuid, p_date date, p_confirm_missing boolean default false)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_from  date;
  v_to    date;
  v_month uuid;
  v_miss  int;
  t       record;
begin
  perform require_user();
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  -- One close at a time per mess: a retry or a second manager waits here and
  -- then sees the month closed, so the snapshot is written exactly once.
  perform pg_advisory_xact_lock(hashtextextended('close_month:' || p_mess::text, 32));
  select start_date, end_date into v_from, v_to from month_period(p_mess, p_date);

  if month_is_closed(p_mess, v_from) then
    perform fail('MONTH_CLOSED');
  end if;
  -- Months close in order: earlier activity must be covered by a closed month ending here.
  if not exists (select 1 from months where mess_id = p_mess and status = 'closed' and end_date = v_from)
     and (exists (select 1 from meal_entries where mess_id = p_mess and date < v_from)
          or exists (select 1 from bazars where mess_id = p_mess and deleted_at is null and date < v_from)
          or exists (select 1 from expenses where mess_id = p_mess and deleted_at is null and date < v_from)
          or exists (select 1 from deposits where mess_id = p_mess and deleted_at is null and date < v_from)) then
    perform fail('PREVIOUS_MONTH_OPEN');
  end if;
  if v_to > dhaka_today() then
    perform fail('MONTH_NOT_ENDED');
  end if;
  if exists (select 1 from month_pending_items(p_mess, v_from, v_to)
             where pending_deposits + pending_bazar_requests > 0) then
    perform fail('PENDING_ITEMS');
  end if;
  -- The automatic meal job must have finished the month's last day (status ok,
  -- verified cell by cell), not merely have run.
  if exists (select 1 from messes ms where ms.id = p_mess and ms.auto_meals and ms.auto_meals_since <= v_to - 1)
     and not exists (select 1 from auto_meal_runs r
                     where r.mess_id = p_mess and r.date = v_to - 1 and r.status = 'ok') then
    perform fail('AUTO_MEALS_PENDING');
  end if;
  select count(*)::int into v_miss from month_missing_meals(p_mess, v_from, v_to);
  if v_miss > 0 and not coalesce(p_confirm_missing, false) then
    perform fail('MISSING_MEALS');
  end if;

  -- The figures are computed live once, here, and frozen.
  select * into t from month_totals_live(p_mess, v_from, v_to);
  insert into months (mess_id, start_date, end_date, status, closed_at, closed_by,
                      food_total, total_meals, meal_rate, extra_total, credit_total,
                      closed_missing, reopened_at, reopen_reason, totals_reconstructed)
  values (p_mess, v_from, v_to, 'closed', now(), auth.uid(),
          t.food_total, t.total_meals, t.meal_rate, t.extra_total, t.credit_total, v_miss, null, null, false)
  on conflict (mess_id, start_date)
    do update set status = 'closed', closed_at = now(), closed_by = auth.uid(),
                  food_total = excluded.food_total, total_meals = excluded.total_meals,
                  meal_rate = excluded.meal_rate, extra_total = excluded.extra_total,
                  credit_total = excluded.credit_total, closed_missing = excluded.closed_missing,
                  reopened_at = null, reopen_reason = null, totals_reconstructed = false
  returning id into v_month;

  delete from month_member_summary where month_id = v_month;
  insert into month_member_summary
    (month_id, mess_id, member_id, meals, food_cost, extra_cost, credit, opening_balance, closing_balance)
  select v_month, p_mess, b.member_id, b.meals, b.food_cost, b.extra_cost, b.credit,
         b.opening_balance, b.closing_balance
  from member_balances_live(p_mess, v_from, v_to) b;

  insert into audit_log (mess_id, actor_id, action, entity, entity_id, new)
  values (p_mess, auth.uid(), 'close_month', 'months', v_month,
          jsonb_build_object('start_date', v_from, 'end_date', v_to,
                             'missing_meal_days_confirmed', v_miss));
  return v_month;
end $$;

-- ── reopen ───────────────────────────────────────────────────────────────
create or replace function public.reopen_month(p_month uuid, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v months%rowtype;
begin
  perform require_user();
  select * into v from months where id = p_month;
  if v.id is null or not has_mess_role(v.mess_id, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  if char_length(btrim(coalesce(p_reason, ''))) < 5 then
    perform fail('REASON_REQUIRED');
  end if;
  if exists (select 1 from months where mess_id = v.mess_id and status = 'closed'
             and start_date > v.start_date) then
    perform fail('LATER_MONTH_CLOSED');
  end if;
  update months
  set status = 'open', closed_at = null, closed_by = null,
      reopened_at = now(), reopen_reason = btrim(p_reason)
  where id = p_month;
  insert into audit_log (mess_id, actor_id, action, entity, entity_id, reason, new)
  values (v.mess_id, auth.uid(), 'reopen_month', 'months', p_month, btrim(p_reason),
          jsonb_build_object('start_date', v.start_date, 'end_date', v.end_date));
end $$;

-- Members hear about a close and about a reopen (the one-time "corrected" close
-- is announced again, since the figures changed).
create or replace function public.push_on_month() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_mess text;
begin
  select name into v_mess from messes where id = new.mess_id;
  if new.status = 'closed' and (tg_op = 'INSERT' or old.status <> 'closed') then
    perform push_enqueue(push_mess_users(new.mess_id, null, null), 'month_closed',
      'মাস বন্ধ হয়েছে', format('%s: মাসের হিসাব চূড়ান্ত, আপনার ব্যালেন্স দেখুন', v_mess),
      'Month closed', format('%s: the month is final, check your balance', v_mess),
      '/money/months');
  elsif tg_op = 'UPDATE' and old.status = 'closed' and new.status = 'open' then
    perform push_enqueue(push_mess_users(new.mess_id, null, auth.uid()), 'month_reopened',
      'মাসের হিসাব সংশোধন হচ্ছে', format('%s: ম্যানেজার হিসাব সংশোধন করছেন, ব্যালেন্স আবার বদলাতে পারে', v_mess),
      'Month being corrected', format('%s: the manager is correcting the month; balances may change', v_mess),
      '/money/months');
  end if;
  return null;
end $$;

-- ── my previous month, final or provisional ──────────────────────────────
drop function public.my_last_month(uuid);
create function public.my_last_month(p_mess uuid)
returns table (start_date date, end_date date, status public.month_status, closed_at timestamptz,
               meals numeric, food_cost numeric, extra_cost numeric, credit numeric,
               opening_balance numeric, closing_balance numeric,
               provisional boolean, reopened_at timestamptz)
language sql stable set search_path = public as $$
  with cur as (select * from month_period(p_mess, dhaka_today())),
       prev as (select p.* from cur, month_period(p_mess, cur.start_date - 1) p)
  select prev.start_date, prev.end_date, coalesce(mo.status, 'open'), mo.closed_at,
         b.meals, b.food_cost, b.extra_cost, b.credit, b.opening_balance, b.closing_balance,
         coalesce(mo.status, 'open') <> 'closed', mo.reopened_at
  from prev
  left join months mo on mo.mess_id = p_mess and mo.start_date = prev.start_date
  left join mess_members me on me.mess_id = p_mess and me.user_id = auth.uid()
  left join lateral member_balances(p_mess, prev.start_date, prev.end_date) b on b.member_id = me.id
  where is_mess_member(p_mess)
    and (mo.status = 'closed'
         or exists (select 1 from meal_entries e where e.mess_id = p_mess
                    and e.date >= prev.start_date and e.date < prev.end_date)
         or exists (select 1 from bazars bz where bz.mess_id = p_mess and bz.deleted_at is null
                    and bz.date >= prev.start_date and bz.date < prev.end_date))
  limit 1;
$$;
