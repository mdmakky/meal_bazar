-- 0021_dashboard_v2: the role-aware Home.
-- All security invoker: members already read every table these touch (RLS),
-- so a non-member gets zeros / no rows.

-- Manager "needs attention" counts for the day p_date.
--   pending_deposits   deposits waiting for verification (any date)
--   pending_members    join requests
--   meals_missing      active members present on p_date with no meal row that day
--   pending_recurring  monthly bills not posted in p_date's period
create or replace function public.manager_attention(p_mess uuid, p_date date)
returns table (pending_deposits int, pending_members int, meals_missing int, pending_recurring int)
language sql stable set search_path = public as $$
  select
    (select count(*)::int from deposits d
     where d.mess_id = p_mess and d.deleted_at is null and d.status = 'pending'),
    (select count(*)::int from mess_members m
     where m.mess_id = p_mess and m.status = 'pending'),
    (select count(*)::int from mess_members m
     where m.mess_id = p_mess and m.status = 'active' and is_present(m, p_date)
       and not exists (select 1 from meal_entries e
                       where e.member_id = m.id and e.date = p_date)),
    pending_recurring_count(p_mess, p_date)
  where is_mess_member(p_mess);
$$;

-- Cash in the mess fund for [p_from, p_to): verified deposits in, minus bazar
-- and expenses paid from the fund (paid_by_member_id null). Own-pocket
-- payments never touch the fund; pending deposits are reported, not counted.
create or replace function public.mess_cash(p_mess uuid, p_from date, p_to date)
returns table (deposits_in numeric, fund_spent numeric, cash numeric, pending_deposits numeric)
language sql stable set search_path = public as $$
  with d as (
    select coalesce(sum(amount) filter (where status = 'verified'), 0) as v,
           coalesce(sum(amount) filter (where status = 'pending'), 0) as p
    from deposits
    where mess_id = p_mess and deleted_at is null and date >= p_from and date < p_to
  ),
  s as (
    select coalesce(sum(amount), 0) as v from (
      select amount from bazars
      where mess_id = p_mess and deleted_at is null and paid_by_member_id is null
        and date >= p_from and date < p_to
      union all
      select amount from expenses
      where mess_id = p_mess and deleted_at is null and paid_by_member_id is null
        and date >= p_from and date < p_to
    ) x
  )
  select d.v, s.v, d.v - s.v, d.p
  from d, s
  where is_mess_member(p_mess);
$$;

-- Mess transparency: each member's verified deposits, own-pocket payments
-- and closing balance (from member_balances, so it always agrees with it).
create or replace function public.member_transparency(p_mess uuid, p_from date, p_to date)
returns table (member_id uuid, display_name text, deposits numeric, own_pocket numeric,
               closing_balance numeric)
language sql stable set search_path = public as $$
  select b.member_id, b.display_name,
         coalesce((select sum(d.amount) from deposits d
                   where d.mess_id = p_mess and d.member_id = b.member_id
                     and d.deleted_at is null and d.status = 'verified'
                     and d.date >= p_from and d.date < p_to), 0),
         coalesce((select sum(x.amount) from (
                     select amount from bazars
                     where mess_id = p_mess and paid_by_member_id = b.member_id
                       and deleted_at is null and date >= p_from and date < p_to
                     union all
                     select amount from expenses
                     where mess_id = p_mess and paid_by_member_id = b.member_id
                       and deleted_at is null and date >= p_from and date < p_to) x), 0),
         b.closing_balance
  from member_balances(p_mess, p_from, p_to) b
  order by b.closing_balance, b.display_name;
$$;

-- What others recorded that concerns the caller, newest first (audit_log).
-- Concerns me: my meal changes (updates, deletes, and inserts that carry an
-- off or a guest, so the daily "fill" does not flood it), my deposits, bazar I
-- paid for or went to, expenses I paid for or share. My own actions are left out.
create or replace function public.my_activity(p_mess uuid, p_limit int default 30)
returns table (id bigint, at timestamptz, action text, entity text, ref_type text,
               ref_id uuid, actor_id uuid, actor_name text, old jsonb, new jsonb)
language sql stable set search_path = public as $$
  with me as (
    select m.id from mess_members m
    where m.mess_id = p_mess and m.user_id = auth.uid() and m.status in ('active', 'inactive')
  ),
  rows as (
    select a.*, coalesce(a.new, a.old) as r from audit_log a
    where a.mess_id = p_mess
      and a.entity in ('meal_entries', 'deposits', 'bazars', 'expenses')
      and a.actor_id is distinct from auth.uid()
  )
  select a.id, a.at, a.action, a.entity,
         case a.entity when 'meal_entries' then 'meal' when 'deposits' then 'deposit'
                       when 'bazars' then 'bazar' else 'expense' end,
         a.entity_id,
         a.actor_id,
         (select am.display_name from mess_members am
          where am.mess_id = p_mess and am.user_id = a.actor_id limit 1),
         a.old, a.new
  from rows a, me
  where case a.entity
    when 'meal_entries' then
      (a.r ->> 'member_id')::uuid = me.id
      and (a.action <> 'insert'
           or (a.r ->> 'is_off')::boolean or (a.r ->> 'guest_count')::int > 0)
    when 'deposits' then (a.r ->> 'member_id')::uuid = me.id
    when 'bazars' then
      me.id in ((a.new ->> 'paid_by_member_id')::uuid, (a.old ->> 'paid_by_member_id')::uuid,
                (a.r ->> 'buyer_member_id')::uuid)
      or exists (select 1 from bazar_buyers bb where bb.bazar_id = a.entity_id and bb.member_id = me.id)
    else
      me.id in ((a.new ->> 'paid_by_member_id')::uuid, (a.old ->> 'paid_by_member_id')::uuid)
      or exists (select 1 from expense_shares s where s.expense_id = a.entity_id and s.member_id = me.id)
  end
  order by a.at desc, a.id desc
  limit least(greatest(coalesce(p_limit, 30), 1), 100);
$$;
