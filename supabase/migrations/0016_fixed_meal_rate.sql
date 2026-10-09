-- 0016_fixed_meal_rate: a mess may announce a fixed meal rate instead of the
-- calculated one (PRODUCT_RULES §3). A month may override the rate.
-- member_balances (0012) charges round(meals × month_totals.meal_rate, 2), so
-- only month_totals changes; close_month snapshots whatever mode is in force.

alter table public.messes
  add column meal_rate_mode text not null default 'calculated'
    check (meal_rate_mode in ('calculated', 'fixed')),
  add column fixed_meal_rate numeric(12,2) check (fixed_meal_rate > 0),
  add constraint messes_fixed_rate_required
    check (meal_rate_mode <> 'fixed' or fixed_meal_rate is not null);

alter table public.months
  add column fixed_meal_rate numeric(12,2) check (fixed_meal_rate > 0);

-- The fixed rate in force for the month starting p_from, or null (calculated).
-- A month's own rate wins; else the mess's rate when its mode is 'fixed'.
create or replace function public.month_fixed_rate(p_mess uuid, p_from date) returns numeric
language sql stable set search_path = public as $$
  select coalesce(mo.fixed_meal_rate,
                  case when m.meal_rate_mode = 'fixed' then m.fixed_meal_rate end)
  from messes m
  left join months mo on mo.mess_id = m.id and mo.start_date = p_from
  where m.id = p_mess;
$$;

-- Same as 0004 except meal_rate: the fixed rate when one is in force.
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
  ), fx as (
    select month_fixed_rate(p_mess, p_from) as v
  )
  select food.v,
         meals.v,
         case when fx.v is not null then fx.v
              when meals.v > 0 then food.v / meals.v else 0 end,
         coalesce((select sum(amount) from expenses
                   where mess_id = p_mess and deleted_at is null and split = 'equal'
                     and date >= p_from and date < p_to), 0),
         coalesce((select sum(amount) from deposits
                   where mess_id = p_mess and deleted_at is null and status = 'verified'
                     and date >= p_from and date < p_to), 0)
  from food, meals, fx;
$$;

-- Mode and rate for a period. surplus_or_deficit = food_total − rate × total_meals
-- (reported, never charged): > 0 means bazar cost more than the rate collected.
-- Outsiders get no row (messes RLS).
create or replace function public.month_rate_info(p_mess uuid, p_from date, p_to date)
returns table (mode text, rate numeric, calculated_rate numeric, food_total numeric,
               total_meals numeric, surplus_or_deficit numeric)
language sql stable set search_path = public as $$
  select case when fx is not null then 'fixed' else 'calculated' end,
         t.meal_rate,
         case when t.total_meals > 0 then t.food_total / t.total_meals else 0 end,
         t.food_total,
         t.total_meals,
         round(t.food_total - t.meal_rate * t.total_meals, 2)
  from messes m
  cross join month_totals(p_mess, p_from, p_to) t
  cross join month_fixed_rate(p_mess, p_from) fx
  where m.id = p_mess;
$$;

-- Manager: set (or clear with null) one month's own rate. Creates the open
-- month row if needed; refused in a closed month.
create or replace function public.set_month_meal_rate(p_mess uuid, p_date date, p_rate numeric)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_from date;
  v_to   date;
begin
  perform require_user();
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  select start_date, end_date into v_from, v_to from month_period(p_mess, p_date);
  if month_is_closed(p_mess, v_from) then
    perform fail('MONTH_CLOSED');
  end if;
  insert into months (mess_id, start_date, end_date, fixed_meal_rate)
  values (p_mess, v_from, v_to, p_rate)
  on conflict (mess_id, start_date) do update set fixed_meal_rate = p_rate;
  insert into audit_log (mess_id, actor_id, action, entity, new)
  values (p_mess, auth.uid(), 'set_month_meal_rate', 'months',
          jsonb_build_object('start_date', v_from, 'fixed_meal_rate', p_rate));
end $$;
