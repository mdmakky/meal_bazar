-- 0012_expense_shares: share an equal-split expense among selected members.
-- An expense with share rows is split among those members in proportion to
-- weight (equal weights = equal split among them); without share rows the
-- old rule applies (equal among members present on the date). Shares only
-- apply to split = 'equal' expenses; a 'meal' expense is food cost.
-- A table rather than a new split_method value: ALTER TYPE ... ADD VALUE
-- cannot be used in the same transaction that adds it.

create table public.expense_shares (
  expense_id uuid not null references public.expenses(id) on delete cascade,
  mess_id    uuid not null references public.messes(id) on delete cascade,
  member_id  uuid not null,
  weight     numeric(6,2) not null default 1 check (weight > 0),
  primary key (expense_id, member_id),
  foreign key (member_id, mess_id) references public.mess_members(id, mess_id)
);
create index expense_shares_mess_idx on public.expense_shares(mess_id);

-- Share rows always belong to the expense's mess.
create or replace function public.expense_share_mess() returns trigger
language plpgsql as $$
begin
  select mess_id into new.mess_id from expenses where id = new.expense_id;
  return new;
end $$;
create trigger expense_shares_mess before insert or update on public.expense_shares
  for each row execute function public.expense_share_mess();

-- Closed-month guard via the parent expense's date.
create or replace function public.guard_closed_month_share() returns trigger
language plpgsql as $$
begin
  if exists (select 1 from expenses e
             where e.id in (old.expense_id, new.expense_id) and month_is_closed(e.mess_id, e.date)) then
    perform fail('MONTH_CLOSED');
  end if;
  return coalesce(new, old);
end $$;
create trigger expense_shares_closed_month before insert or update or delete on public.expense_shares
  for each row execute function public.guard_closed_month_share();

alter table public.expense_shares enable row level security;
create policy expense_shares_read on public.expense_shares for select using (is_mess_member(mess_id));
create policy expense_shares_write on public.expense_shares for all
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));

-- Replaces an expense's shares in one go ([] = back to the equal split).
-- Security invoker: RLS decides who may write.
create or replace function public.set_expense_shares(p_expense uuid, p_shares jsonb) returns void
language sql set search_path = public as $$
  delete from expense_shares where expense_id = p_expense;
  insert into expense_shares (expense_id, member_id, weight)
  select p_expense, (s->>'member_id')::uuid, coalesce((s->>'weight')::numeric, 1)
  from jsonb_array_elements(coalesce(p_shares, '[]')) s;
$$;

-- Same as 0004 except `ex`: shared expenses go by weight.
create or replace function public.member_balances(p_mess uuid, p_from date, p_to date)
returns table (member_id uuid, display_name text, status public.member_status,
               meals numeric, food_cost numeric, extra_cost numeric, credit numeric,
               opening_balance numeric, closing_balance numeric)
language sql stable set search_path = public as $$
  with t as (select * from month_totals(p_mess, p_from, p_to)),
  ml as (select * from member_meal_totals(p_mess, p_from, p_to)),
  eq as (
    select e.* from expenses e
    where e.mess_id = p_mess and e.deleted_at is null and e.split = 'equal'
      and e.date >= p_from and e.date < p_to
  ),
  ex as (
    select x.member_id, sum(x.v) as v from (
      select m.id as member_id, round(e.amount / n.cnt, 2) as v
      from eq e
      cross join lateral (select count(*) as cnt from mess_members p
                          where p.mess_id = e.mess_id and is_present(p, e.date)) n
      join mess_members m on m.mess_id = e.mess_id and is_present(m, e.date)
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
