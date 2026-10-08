-- Dashboard series: daily meals, spending by category, monthly history.
\set M '''11110000-0000-0000-0000-00000000000a'''
\set X '''11110000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:X);

select test.act_as(:M);
select create_mess('Dash Mess', 'Manager') as mess \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
select id as bfast from meal_types where mess_id = :'mess' and name = 'সকাল' \gset
select id as wifi from expense_categories where mess_id = :'mess' and name = 'ওয়াইফাই' \gset
select id as gas from expense_categories where mess_id = :'mess' and name = 'গ্যাস' \gset
update mess_members set joined_on = '2026-08-01' where id = :'mgr';

-- Oct 2: lunch 1 + 2 guests (3), breakfast weight 0.5 → 0.5. Oct 3: half lunch.
insert into meal_entries (mess_id, member_id, meal_type_id, date, count, guest_count)
values (:'mess', :'mgr', :'lunch', '2026-10-02', 1, 2),
       (:'mess', :'mgr', :'bfast', '2026-10-02', 1, 0),
       (:'mess', :'mgr', :'lunch', '2026-10-03', 0.5, 0),
       (:'mess', :'mgr', :'lunch', '2026-11-01', 1, 0);

select test.check((select count(*) from daily_meal_totals(:'mess', '2026-10-01', '2026-10-05')) = 4, 'daily: zero-filled, end exclusive');
select test.check((select meals = 3.5 from daily_meal_totals(:'mess', '2026-10-01', '2026-10-05') where date = '2026-10-02'), 'daily: guests and weights');
select test.check((select meals = 0.5 from daily_meal_totals(:'mess', '2026-10-01', '2026-10-05') where date = '2026-10-03'), 'daily: half meal');
select test.check((select meals = 0 from daily_meal_totals(:'mess', '2026-10-01', '2026-10-05') where date = '2026-10-01'), 'daily: empty day is 0');
select test.check((select sum(meals) from daily_meal_totals(:'mess', '2026-10-01', '2026-11-01'))
                  = (select total_meals from month_totals(:'mess', '2026-10-01', '2026-11-01')), 'daily sums to month_totals');

-- Spending by category: bazar row + categories, soft-deleted ignored, largest first.
insert into bazars (mess_id, date, amount) values (:'mess', '2026-10-03', 1000), (:'mess', '2026-10-07', 410);
insert into bazars (mess_id, date, amount, deleted_at) values (:'mess', '2026-10-08', 999, now());
insert into expenses (mess_id, date, category_id, amount, split) values
  (:'mess', '2026-10-15', :'wifi', 500, 'equal'),
  (:'mess', '2026-10-16', :'gas', 300, 'meal'),
  (:'mess', '2026-10-17', :'gas', 200, 'equal'),
  (:'mess', '2026-11-02', :'wifi', 700, 'equal');
select test.check((select array_agg(category || '=' || total::int order by category)
                   from expense_by_category(:'mess', '2026-10-01', '2026-11-01'))
                  = (select array_agg(x order by x) from unnest(array['বাজার=1410', 'গ্যাস=500', 'ওয়াইফাই=500']) x), 'by category');
select test.check((select category = 'বাজার' and is_bazar from expense_by_category(:'mess', '2026-10-01', '2026-11-01') limit 1), 'largest first, bazar flagged');
select test.check((select count(*) from expense_by_category(:'mess', '2026-10-01', '2026-11-01') where is_bazar) = 1, 'one bazar row');
select test.check((select count(*) from expense_by_category(:'mess', '2026-12-01', '2027-01-01')) = 0, 'empty month: no rows');

-- Monthly history: oldest first, live totals per period, honours month_start_day.
select test.check((select count(*) from month_history(:'mess', 6, '2026-11-10')) = 6, 'history: 6 periods');
select test.check((select array_agg(start_date order by start_date) from month_history(:'mess', 3, '2026-11-10'))
                  = array['2026-09-01', '2026-10-01', '2026-11-01']::date[], 'history: periods');
select test.check((select h.food_total = t.food_total and h.extra_total = t.extra_total and h.meal_rate = t.meal_rate
                   from month_history(:'mess', 3, '2026-11-10') h, month_totals(:'mess', '2026-10-01', '2026-11-01') t
                   where h.start_date = '2026-10-01'), 'history matches month_totals');
select test.check((select food_total = 1710 and extra_total = 700
                   from month_history(:'mess', 3, '2026-11-10') where start_date = '2026-10-01'), 'history: Oct food = bazar + meal-split');
select test.check((select food_total = 0 and meal_rate = 0
                   from month_history(:'mess', 3, '2026-11-10') where start_date = '2026-09-01'), 'history: empty month is 0');
update messes set month_start_day = 5 where id = :'mess';
select test.check((select array_agg(start_date order by start_date) from month_history(:'mess', 2, '2026-11-04'))
                  = array['2026-09-05', '2026-10-05']::date[], 'history: month_start_day');
update messes set month_start_day = 1 where id = :'mess';

-- Outsider: nothing.
select test.act_as(:X);
select test.check((select count(*) from daily_meal_totals(:'mess', '2026-10-01', '2026-11-01')) = 0, 'outsider: no daily');
select test.check((select count(*) from expense_by_category(:'mess', '2026-10-01', '2026-11-01')) = 0, 'outsider: no categories');
select test.check((select count(*) from month_history(:'mess', 6, '2026-11-10')) = 0, 'outsider: no history');
select test.act_as(null);
