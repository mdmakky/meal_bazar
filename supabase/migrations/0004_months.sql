-- 0004_months: the calculation engine (single source of truth) + month close.
-- Rules: PRODUCT_RULES.md §3–4. All functions are security invoker (RLS applies)
-- unless noted.

create type public.month_status as enum ('open', 'closed');

create table public.months (
  id            uuid primary key default gen_random_uuid(),
  mess_id       uuid not null references public.messes(id) on delete cascade,
  start_date    date not null,
  end_date      date not null,                 -- exclusive
  status        public.month_status not null default 'open',
  closed_at     timestamptz,
  closed_by     uuid,
  created_at    timestamptz not null default now(),
  unique (mess_id, start_date),
  check (end_date > start_date)
);

create table public.month_member_summary (
  month_id        uuid not null references public.months(id) on delete cascade,
  mess_id         uuid not null references public.messes(id) on delete cascade,
  member_id       uuid not null references public.mess_members(id),
  meals           numeric(10,2) not null,
  food_cost       numeric(12,2) not null,
  extra_cost      numeric(12,2) not null,
  credit          numeric(12,2) not null,
  opening_balance numeric(12,2) not null,
  closing_balance numeric(12,2) not null,
  primary key (month_id, member_id)
);

-- Billing period containing p_date, from the mess's month_start_day.
create or replace function public.month_period(p_mess uuid, p_date date)
returns table (start_date date, end_date date)
language sql stable set search_path = public as $$
  with s as (
    select make_date(extract(year from d)::int, extract(month from d)::int, m.month_start_day) as start_date
    from messes m,
         lateral (select case when extract(day from p_date) >= m.month_start_day
                              then p_date else (p_date - interval '1 month')::date end as d) x
    where m.id = p_mess
  )
  select start_date, (start_date + interval '1 month')::date from s;
$$;

-- Present on date d: joined and not yet left (PRODUCT_RULES §2).
create or replace function public.is_present(m public.mess_members, d date) returns boolean
language sql immutable as $$
  select m.status <> 'pending' and m.joined_on <= d and (m.left_on is null or d < m.left_on);
$$;

create or replace function public.month_totals(p_mess uuid, p_from date, p_to date)
returns table (food_total numeric, total_meals numeric, meal_rate numeric,
               extra_total numeric, credit_total numeric)
language sql stable set search_path = public as $$
  with food as (
    select coalesce((select sum(amount) from bazars
                     where mess_id = p_mess and deleted_at is null and date >= p_from and date < p_to), 0)
         + coalesce((select sum(amount) from expenses
                     where mess_id = p_mess and deleted_at is null and split = 'meal'
                       and date >= p_from and date < p_to), 0) as v
  ), meals as (
    select coalesce(sum(meals), 0) as v from member_meal_totals(p_mess, p_from, p_to)
  )
  select food.v,
         meals.v,
         case when meals.v > 0 then food.v / meals.v else 0 end,
         coalesce((select sum(amount) from expenses
                   where mess_id = p_mess and deleted_at is null and split = 'equal'
                     and date >= p_from and date < p_to), 0),
         coalesce((select sum(amount) from deposits
                   where mess_id = p_mess and deleted_at is null and status = 'verified'
                     and date >= p_from and date < p_to), 0)
  from food, meals;
$$;

-- One row per member with every figure from PRODUCT_RULES §3 (live computation).
create or replace function public.member_balances(p_mess uuid, p_from date, p_to date)
returns table (member_id uuid, display_name text, status public.member_status,
               meals numeric, food_cost numeric, extra_cost numeric, credit numeric,
               opening_balance numeric, closing_balance numeric)
language sql stable set search_path = public as $$
  with t as (select * from month_totals(p_mess, p_from, p_to)),
  ml as (select * from member_meal_totals(p_mess, p_from, p_to)),
  ex as (
    select m.id as member_id, sum(round(e.amount / n.cnt, 2)) as v
    from expenses e
    cross join lateral (select count(*) as cnt from mess_members p
                        where p.mess_id = e.mess_id and is_present(p, e.date)) n
    join mess_members m on m.mess_id = e.mess_id and is_present(m, e.date)
    where e.mess_id = p_mess and e.deleted_at is null and e.split = 'equal'
      and e.date >= p_from and e.date < p_to
    group by m.id
  ),
  cr as (
    select x.member_id, sum(x.amount) as v from (
      select d.member_id, d.amount from deposits d
      where d.mess_id = p_mess and d.deleted_at is null and d.status = 'verified'
        and d.date >= p_from and d.date < p_to
      union all
      select b.paid_by_member_id, b.amount from bazars b
      where b.mess_id = p_mess and b.deleted_at is null and b.paid_by_member_id is not null
        and b.date >= p_from and b.date < p_to
      union all
      select e.paid_by_member_id, e.amount from expenses e
      where e.mess_id = p_mess and e.deleted_at is null and e.paid_by_member_id is not null
        and e.date >= p_from and e.date < p_to
    ) x group by x.member_id
  ),
  op as (
    select s.member_id, s.closing_balance as v
    from month_member_summary s join months mo on mo.id = s.month_id
    where mo.mess_id = p_mess and mo.status = 'closed' and mo.end_date = p_from
  ),
  rows as (
    select m.id, m.display_name, m.status, m.joined_on, m.left_on,
           coalesce(ml.meals, 0) as meals,
           round(coalesce(ml.meals, 0) * t.meal_rate, 2) as food_cost,
           coalesce(ex.v, 0) as extra_cost,
           coalesce(cr.v, 0) as credit,
           coalesce(op.v, 0) as opening_balance
    from mess_members m
    cross join t
    left join ml on ml.member_id = m.id
    left join ex on ex.member_id = m.id
    left join cr on cr.member_id = m.id
    left join op on op.member_id = m.id
    where m.mess_id = p_mess and m.status <> 'pending'
  )
  select id, display_name, status, meals, food_cost, extra_cost, credit, opening_balance,
         opening_balance + credit - food_cost - extra_cost
  from rows
  where (joined_on < p_to and (left_on is null or left_on > p_from))
     or meals <> 0 or extra_cost <> 0 or credit <> 0 or opening_balance <> 0
  order by display_name;
$$;

-- ── closed-month guard ───────────────────────────────────────────────────
create or replace function public.month_is_closed(p_mess uuid, p_date date) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from months
                 where mess_id = p_mess and status = 'closed'
                   and p_date >= start_date and p_date < end_date);
$$;

create or replace function public.guard_closed_month() returns trigger
language plpgsql as $$
begin
  if tg_op <> 'INSERT' and month_is_closed(old.mess_id, old.date) then
    perform fail('MONTH_CLOSED');
  end if;
  if tg_op <> 'DELETE' and month_is_closed(new.mess_id, new.date) then
    perform fail('MONTH_CLOSED');
  end if;
  return coalesce(new, old);
end $$;

do $$
declare t text;
begin
  foreach t in array array['meal_entries', 'bazars', 'expenses', 'deposits'] loop
    execute format('create trigger %1$s_closed_month before insert or update or delete on public.%1$s
                    for each row execute function public.guard_closed_month()', t);
  end loop;
end $$;

create or replace function public.guard_closed_month_item() returns trigger
language plpgsql as $$
declare
  v_bazar uuid := coalesce(new.bazar_id, old.bazar_id);
begin
  if exists (select 1 from bazars b where b.id = v_bazar and month_is_closed(b.mess_id, b.date)) then
    perform fail('MONTH_CLOSED');
  end if;
  return coalesce(new, old);
end $$;
create trigger bazar_items_closed_month before insert or update or delete on public.bazar_items
  for each row execute function public.guard_closed_month_item();

-- ── close / reopen (manager only) ────────────────────────────────────────
create or replace function public.close_month(p_mess uuid, p_date date) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_from  date;
  v_to    date;
  v_month uuid;
begin
  perform require_user();
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
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

  insert into months (mess_id, start_date, end_date, status, closed_at, closed_by)
  values (p_mess, v_from, v_to, 'closed', now(), auth.uid())
  on conflict (mess_id, start_date)
    do update set status = 'closed', closed_at = now(), closed_by = auth.uid()
  returning id into v_month;

  delete from month_member_summary where month_id = v_month;
  insert into month_member_summary
    (month_id, mess_id, member_id, meals, food_cost, extra_cost, credit, opening_balance, closing_balance)
  select v_month, p_mess, b.member_id, b.meals, b.food_cost, b.extra_cost, b.credit,
         b.opening_balance, b.closing_balance
  from member_balances(p_mess, v_from, v_to) b;

  insert into audit_log (mess_id, actor_id, action, entity, entity_id, new)
  values (p_mess, auth.uid(), 'close_month', 'months', v_month,
          jsonb_build_object('start_date', v_from, 'end_date', v_to));
  return v_month;
end $$;

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
  update months set status = 'open', closed_at = null, closed_by = null where id = p_month;
  insert into audit_log (mess_id, actor_id, action, entity, entity_id, reason, new)
  values (v.mess_id, auth.uid(), 'reopen_month', 'months', p_month, btrim(p_reason),
          jsonb_build_object('start_date', v.start_date, 'end_date', v.end_date));
end $$;

alter table public.months               enable row level security;
alter table public.month_member_summary enable row level security;
-- Writes happen only through close_month / reopen_month (security definer).
create policy months_read on public.months for select using (is_mess_member(mess_id));
create policy month_summary_read on public.month_member_summary for select using (is_mess_member(mess_id));
