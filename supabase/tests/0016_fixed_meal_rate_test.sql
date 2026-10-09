-- Fixed meal rate: worked example at ৳60, calculated mode unchanged, constraints,
-- month override, snapshot at close, outsider.
\set M '''16161616-0000-0000-0000-00000000000a'''
\set X '''16161616-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:X);

select test.act_as(:M);
select create_mess('Fixed Mess', 'Manager') as mess \gset
update mess_members set joined_on = '2026-11-01' where mess_id = :'mess';
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'Rahim', '2026-10-01') returning id as rahim \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'Karim', '2026-10-01') returning id as karim \gset

-- PRODUCT_RULES §3 fixture: Rahim 10 + 2 guests, Karim 8.5, bazar ৳1,410.
insert into meal_entries (mess_id, member_id, meal_type_id, date, count, guest_count)
select :'mess', :'rahim', :'lunch', d::date, 1, case when d = '2026-10-01' then 2 else 0 end
from generate_series('2026-10-01'::date, '2026-10-10', '1 day') d;
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
select :'mess', :'karim', :'lunch', d::date, case when d = '2026-10-01' then 0.5 else 1 end
from generate_series('2026-10-01'::date, '2026-10-09', '1 day') d;
insert into bazars (mess_id, date, amount) values (:'mess', '2026-10-03', 1000), (:'mess', '2026-10-07', 410);

-- Calculated (default): identical to 0004.
select test.check((select meal_rate_mode = 'calculated' and fixed_meal_rate is null from messes where id = :'mess'), 'default calculated');
select test.check((select round(meal_rate, 4) = 68.7805 from month_totals(:'mess', '2026-10-01', '2026-11-01')), 'calculated rate unchanged');
select test.check((select food_cost = 825.37 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'rahim'), 'calculated rahim 825.37');
select test.check((select food_cost = 584.63 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'karim'), 'calculated karim 584.63');
select test.check((select mode = 'calculated' and round(rate, 4) = 68.7805 and round(calculated_rate, 4) = 68.7805
                          and food_total = 1410 and total_meals = 20.5 and surplus_or_deficit = 0
                   from month_rate_info(:'mess', '2026-10-01', '2026-11-01')), 'calculated rate info');

-- Constraints.
select test.expect_error(format($$update messes set meal_rate_mode = 'fixed' where id = %L$$, :'mess'), 'messes_fixed_rate_required');
select test.expect_error(format($$update messes set meal_rate_mode = 'fixed', fixed_meal_rate = 0 where id = %L$$, :'mess'), 'fixed_meal_rate_check');
select test.expect_error(format($$update messes set meal_rate_mode = 'flat' where id = %L$$, :'mess'), 'meal_rate_mode_check');

-- Fixed at ৳60.
update messes set meal_rate_mode = 'fixed', fixed_meal_rate = 60 where id = :'mess';
select test.check((select meal_rate = 60 and food_total = 1410 from month_totals(:'mess', '2026-10-01', '2026-11-01')), 'fixed rate returned');
select test.check((select food_cost = 720.00 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'rahim'), 'rahim 12 × 60 = 720');
select test.check((select food_cost = 510.00 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'karim'), 'karim 8.5 × 60 = 510');
select test.check((select mode = 'fixed' and rate = 60 and round(calculated_rate, 4) = 68.7805
                          and surplus_or_deficit = 180
                   from month_rate_info(:'mess', '2026-10-01', '2026-11-01')), 'fixed rate info: 1410 − 60 × 20.5 = 180');

-- Month override (manager only, wins over the mess rate, clearable).
select set_month_meal_rate(:'mess', '2026-10-15', 70);
select test.check((select food_cost = 840 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'rahim'), 'override 12 × 70');
select test.check((select meal_rate = 60 from month_totals(:'mess', '2026-11-01', '2026-12-01')), 'override only for its month');
update messes set meal_rate_mode = 'calculated' where id = :'mess';
select test.check((select mode = 'fixed' and rate = 70 from month_rate_info(:'mess', '2026-10-01', '2026-11-01')), 'override applies in calculated mess');
select set_month_meal_rate(:'mess', '2026-10-15', null);
select test.check((select round(meal_rate, 4) = 68.7805 from month_totals(:'mess', '2026-10-01', '2026-11-01')), 'override cleared');
select test.expect_error(format($$select set_month_meal_rate(%L, '2026-10-15', -1)$$, :'mess'), 'fixed_meal_rate_check');

-- Close snapshots the mode at close time.
update messes set meal_rate_mode = 'fixed' where id = :'mess';
select close_month(:'mess', '2026-10-01') as oct \gset
select test.check((select food_cost = 720 from month_member_summary where month_id = :'oct' and member_id = :'rahim'), 'snapshot uses fixed rate');
update messes set meal_rate_mode = 'calculated' where id = :'mess';
select test.check((select food_cost = 720 from month_member_summary where month_id = :'oct' and member_id = :'rahim'), 'snapshot survives mode change');
select test.expect_error(format($$select set_month_meal_rate(%L, '2026-10-15', 50)$$, :'mess'), 'MONTH_CLOSED');

-- Outsider: no rate info, cannot set a rate or change mode.
select test.act_as(:X);
select test.check((select count(*) from month_rate_info(:'mess', '2026-10-01', '2026-11-01')) = 0, 'outsider sees no rate info');
select test.expect_error(format($$select set_month_meal_rate(%L, '2026-11-15', 50)$$, :'mess'), 'NOT_MANAGER');
select test.check(test.rows(format($$update messes set meal_rate_mode = 'fixed', fixed_meal_rate = 1 where id = %L$$, :'mess')) = 0, 'outsider cannot change mode');
select test.act_as(null);
