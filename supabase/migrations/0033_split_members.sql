-- 0033_split_members: who shares an equal-split cost.
--  * mess_members.meal_only: a member who only takes part in the meal rate does
--    not get an automatic equal share of rent, Wi-Fi and the like. Manager-only.
--  * recurring bills may name the members who share them (like a one-off
--    expense's "selected members"); posting the bill copies them to
--    expense_shares, so the existing weighted-share maths applies unchanged.
-- Closed months are frozen snapshots (0032), so history is not touched.
-- Contract: DATABASE.md "Who shares a cost (0033)".

alter table public.mess_members add column meal_only boolean not null default false;

-- Only a manager (or a trusted RPC) may set the flag: a member must not be
-- able to exempt themselves from shared costs.
create or replace function public.guard_member_meal_only() returns trigger
language plpgsql as $$
begin
  if (tg_op = 'INSERT' and new.meal_only) or (tg_op = 'UPDATE' and new.meal_only is distinct from old.meal_only) then
    if coalesce(current_setting('meal_bazar.trusted', true), '') <> 'on' and not has_mess_role(new.mess_id, 'manager') then
      perform fail('NOT_MANAGER');
    end if;
  end if;
  return new;
end $$;
create trigger mess_members_meal_only before insert or update on public.mess_members
  for each row execute function public.guard_member_meal_only();

-- The 0012 body with two changes (the meal-only rule and the back-dated-cost rule),
-- under the _live name
-- that member_balances (0032) reads.
create or replace function public.member_balances_live(p_mess uuid, p_from date, p_to date)
returns table (member_id uuid, display_name text, status public.member_status,
               meals numeric, food_cost numeric, extra_cost numeric, credit numeric,
               opening_balance numeric, closing_balance numeric)
language sql stable set search_path = public as $$
  with t as (select * from month_totals(p_mess, p_from, p_to)),
  ml as (select * from member_meal_totals(p_mess, p_from, p_to)),
  -- A cost dated before anyone had joined (a mess starting mid-month and
  -- back-dating its bills) is shared by the first members, as if dated on the
  -- day the mess began, instead of belonging to nobody.
  eq as (
    select e.*, greatest(e.date, (select min(p.joined_on) from mess_members p
                                  where p.mess_id = p_mess and p.status <> 'pending')) as eff
    from expenses e
    where e.mess_id = p_mess and e.deleted_at is null and e.split = 'equal'
      and e.date >= p_from and e.date < p_to
  ),
  ex as (
    select x.member_id, sum(x.v) as v from (
      select m.id as member_id, round(e.amount / n.cnt, 2) as v
      from eq e
      cross join lateral (select count(*) as cnt from mess_members p
                          where p.mess_id = e.mess_id and is_present(p, e.eff) and not p.meal_only) n
      join mess_members m on m.mess_id = e.mess_id and is_present(m, e.eff) and not m.meal_only
      where not exists (select 1 from expense_shares s where s.expense_id = e.id)
      union all
      select s.member_id, round(e.amount * s.weight / w.total, 2)
      from eq e
      join expense_shares s on s.expense_id = e.id
      cross join lateral (select sum(weight) as total from expense_shares
                          where expense_id = e.id) w
    ) x group by x.member_id
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

-- ── who shares a recurring bill ──────────────────────────────────────────
-- No rows = everyone present (as before). Rows = only these members, by weight.
create table public.recurring_expense_members (
  recurring_id uuid not null references public.recurring_expenses(id) on delete cascade,
  member_id    uuid not null,
  mess_id      uuid not null references public.messes(id) on delete cascade,
  weight       numeric(6,2) not null default 1 check (weight > 0),
  primary key (recurring_id, member_id),
  foreign key (member_id, mess_id) references public.mess_members(id, mess_id) on delete cascade
);
create index recurring_expense_members_mess_idx on public.recurring_expense_members(mess_id);
create trigger recurring_expense_members_suspension before insert or update or delete on public.recurring_expense_members
  for each row execute function public.guard_suspension();
alter table public.recurring_expense_members enable row level security;
create policy recurring_expense_members_read on public.recurring_expense_members for select using (is_mess_member(mess_id));
create policy recurring_expense_members_write on public.recurring_expense_members for all
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));

-- Posting a bill now carries its member list into the new expense. Selected
-- members who are no longer present on the bill's date are dropped; if none
-- remain the expense falls back to everyone present (never silently lost).
-- Same contract as 0015: idempotent per (bill, period), manager only, RLS and
-- the closed-month trigger apply and a failure rolls everything back.
create or replace function public.apply_recurring_expenses(p_mess uuid, p_date date) returns int
language plpgsql security invoker set search_path = public as $$
declare
  v_from date;
  n int;
begin
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  select start_date into v_from from month_period(p_mess, p_date);
  -- One statement, so the "expenses added" push stays one per batch (0019).
  with marked as (
    insert into recurring_applied (recurring_id, period_start, mess_id)
    select r.id, v_from, p_mess from recurring_expenses r
    where r.mess_id = p_mess and r.active
    on conflict do nothing
    returning recurring_id
  ), todo as (
    select r.*, gen_random_uuid() as expense_id, v_from + r.day_of_period - 1 as on_date
    from marked join recurring_expenses r on r.id = marked.recurring_id
  ), ins as (
    insert into expenses (id, mess_id, date, category_id, amount, split, note, source)
    select expense_id, p_mess, on_date, category_id, amount, split, note, 'system' from todo
    returning id
  ), sh as (
    insert into expense_shares (expense_id, member_id, weight)
    select t.expense_id, rm.member_id, rm.weight
    from todo t
    join recurring_expense_members rm on rm.recurring_id = t.id
    join mess_members mm on mm.id = rm.member_id
    where t.split = 'equal' and is_present(mm, t.on_date)
    returning 1
  )
  select count(*) into n from ins;
  return n;
end $$;
