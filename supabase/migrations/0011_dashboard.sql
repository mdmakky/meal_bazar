-- 0011_dashboard: read-only series for the dashboard charts (Plan §16–17).
-- All security invoker: RLS on the underlying tables applies to the caller.

-- Billable meals per day in [p_from, p_to), zero-filled; same weighting as
-- member_meal_totals: (count + guests) × weight. Empty for non-members.
create or replace function public.daily_meal_totals(p_mess uuid, p_from date, p_to date)
returns table (date date, meals numeric)
language sql stable set search_path = public as $$
  select d::date,
         coalesce((select sum((e.count + e.guest_count) * t.weight)
                   from meal_entries e join meal_types t on t.id = e.meal_type_id
                   where e.mess_id = p_mess and e.date = d::date), 0)
  from generate_series(p_from, p_to - 1, interval '1 day') d
  where is_mess_member(p_mess)
  order by 1;
$$;

-- Spending by expense category in [p_from, p_to), plus one 'বাজার' row for
-- the bazar total (is_bazar, so a category that happens to be named 'বাজার'
-- is not mistaken for it). Zero rows are left out; largest first.
create or replace function public.expense_by_category(p_mess uuid, p_from date, p_to date)
returns table (category text, total numeric, is_bazar boolean)
language sql stable set search_path = public as $$
  select category, total, is_bazar from (
    select 'বাজার'::text as category, sum(b.amount) as total, true as is_bazar
    from bazars b
    where b.mess_id = p_mess and b.deleted_at is null and b.date >= p_from and b.date < p_to
    union all
    select c.name, sum(e.amount), false
    from expenses e join expense_categories c on c.id = e.category_id
    where e.mess_id = p_mess and e.deleted_at is null and e.date >= p_from and e.date < p_to
    group by c.name
  ) x
  where total > 0
  order by total desc, category;
$$;

-- The last p_months billing periods up to the one containing p_until (oldest
-- first), each with its live month_totals.
create or replace function public.month_history(p_mess uuid, p_months int, p_until date default current_date)
returns table (start_date date, food_total numeric, extra_total numeric, meal_rate numeric)
language sql stable set search_path = public as $$
  select p.start_date, t.food_total, t.extra_total, t.meal_rate
  from month_period(p_mess, p_until) cur
  cross join generate_series(least(greatest(p_months, 1), 24) - 1, 0, -1) k
  cross join lateral month_period(p_mess, (cur.start_date - make_interval(months => k))::date) p
  cross join lateral month_totals(p_mess, p.start_date, p.end_date) t
  order by p.start_date;
$$;
