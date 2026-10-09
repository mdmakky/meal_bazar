-- Calculation engine: PRODUCT_RULES §3 worked example, close/reopen, guard, carry-forward.
\set M '''33333333-0000-0000-0000-00000000000a'''
\set X '''33333333-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:X);

select test.act_as(:M);
select create_mess('Calc Mess', 'Manager') as mess \gset
-- Keep the fixture to exactly Rahim and Karim: manager joins after October.
update mess_members set joined_on = '2026-11-01' where mess_id = :'mess';
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
select id as wifi from expense_categories where mess_id = :'mess' and name = 'ওয়াইফাই' \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'Rahim', '2026-10-01') returning id as rahim \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'Karim', '2026-10-01') returning id as karim \gset

-- month_period honours month_start_day.
select test.check((select start_date = '2026-10-01' and end_date = '2026-11-01' from month_period(:'mess', '2026-10-31')), 'period day 1');
update messes set month_start_day = 5 where id = :'mess';
select test.check((select start_date = '2026-09-05' and end_date = '2026-10-05' from month_period(:'mess', '2026-10-04')), 'period before start day');
select test.check((select start_date = '2026-10-05' from month_period(:'mess', '2026-10-05')), 'period on start day');
update messes set month_start_day = 1 where id = :'mess';

-- Worked example: Rahim 10 + 2 guests, Karim 8.5; bazar ৳1,410; WiFi ৳500 equal; Rahim deposits ৳1,500.
insert into meal_entries (mess_id, member_id, meal_type_id, date, count, guest_count)
select :'mess', :'rahim', :'lunch', d::date, 1, case when d = '2026-10-01' then 2 else 0 end
from generate_series('2026-10-01'::date, '2026-10-10', '1 day') d;
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
select :'mess', :'karim', :'lunch', d::date, case when d = '2026-10-01' then 0.5 else 1 end
from generate_series('2026-10-01'::date, '2026-10-09', '1 day') d;
insert into bazars (mess_id, date, amount) values (:'mess', '2026-10-03', 1000), (:'mess', '2026-10-07', 410);
insert into expenses (mess_id, date, category_id, amount, split) values (:'mess', '2026-10-15', :'wifi', 500, 'equal');
insert into deposits (mess_id, member_id, date, amount, method, trx_id) values (:'mess', :'rahim', '2026-10-02', 1500, 'bkash', 'BK7XQ2');
insert into deposits (mess_id, member_id, date, amount, status) values (:'mess', :'karim', '2026-10-02', 999, 'pending');

select test.check((select food_total = 1410 and total_meals = 20.5 and round(meal_rate, 4) = 68.7805
                   and extra_total = 500 and credit_total = 1500
                   from month_totals(:'mess', '2026-10-01', '2026-11-01')), 'month totals');
select test.check((select meals = 12 and food_cost = 825.37 and extra_cost = 250 and credit = 1500 and closing_balance = 424.63
                   from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'rahim'), 'rahim balance +424.63');
select test.check((select meals = 8.5 and food_cost = 584.63 and extra_cost = 250 and credit = 0 and closing_balance = -834.63
                   from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'karim'), 'karim due −834.63 (pending deposit ignored)');
select test.check((select count(*) from member_balances(:'mess', '2026-10-01', '2026-11-01')) = 2, 'manager (joins in Nov) excluded from Oct');

-- Own-pocket bazar is a credit; soft-deleted rows don't count; zero meals → rate 0.
insert into bazars (mess_id, date, amount, paid_by_member_id) values (:'mess', '2026-10-20', 90, :'karim') returning id as kb \gset
select test.check((select credit = 90 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'karim'), 'own-pocket bazar credited');
update bazars set deleted_at = now() where id = :'kb';
select test.check((select food_total = 1410 from month_totals(:'mess', '2026-10-01', '2026-11-01')), 'soft-deleted bazar ignored');
select test.check((select meal_rate = 0 from month_totals(:'mess', '2026-12-01', '2027-01-01')), 'no meals → rate 0');

-- Equal split only among members present on the expense date.
update mess_members set status = 'left', left_on = '2026-10-15' where id = :'karim';
select test.check((select extra_cost = 500 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'rahim'), 'left member not in later split');
select test.check((select closing_balance = -584.63 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'karim'), 'left member keeps history');
update mess_members set status = 'active', left_on = null where id = :'karim';

-- Close October: snapshot, guard, ordering, carry-forward.
select test.expect_error($$select close_month('33333333-0000-0000-0000-00000000dead', '2026-10-01')$$, 'NOT_MANAGER');
select test.expect_error(format($$select close_month(%L, '2026-11-10')$$, :'mess'), 'PREVIOUS_MONTH_OPEN');
-- A pending deposit must be decided first (0026).
select test.expect_error(format($$select close_month(%L, '2026-10-20')$$, :'mess'), 'PENDING_ITEMS');
update deposits set status = 'rejected' where mess_id = :'mess' and status = 'pending';
select close_month(:'mess', '2026-10-20') as oct \gset
select test.check((select closing_balance = 424.63 from month_member_summary where month_id = :'oct' and member_id = :'rahim'), 'snapshot written');
select test.expect_error(format($$update meal_entries set count = 0 where member_id = %L and date = '2026-10-02'$$, :'rahim'), 'MONTH_CLOSED');
select test.expect_error(format($$insert into bazars (mess_id, date, amount) values (%L, '2026-10-31', 10)$$, :'mess'), 'MONTH_CLOSED');
select test.expect_error(format($$update bazars set date = '2026-10-31' where id = %L$$, :'kb'), 'MONTH_CLOSED');
select test.expect_error(format($$delete from deposits where member_id = %L$$, :'rahim'), 'MONTH_CLOSED');
select test.expect_error(format($$select close_month(%L, '2026-10-01')$$, :'mess'), 'MONTH_CLOSED');

insert into deposits (mess_id, member_id, date, amount) values (:'mess', :'karim', '2026-11-02', 1000);
select test.check((select opening_balance = -834.63 and closing_balance = 165.37
                   from member_balances(:'mess', '2026-11-01', '2026-12-01') where member_id = :'karim'), 'Nov opening carries Oct closing');
select close_month(:'mess', '2026-11-01') as nov \gset

-- Reopen: needs reason, must reopen later months first, audited.
select test.expect_error(format($$select reopen_month(%L, 'oops')$$, :'oct'), 'REASON_REQUIRED');
select test.expect_error(format($$select reopen_month(%L, 'Fix wrong bazar')$$, :'oct'), 'LATER_MONTH_CLOSED');
select reopen_month(:'nov', 'Late deposit correction');
select reopen_month(:'oct', 'Fix wrong bazar amount');
update bazars set amount = 400 where mess_id = :'mess' and date = '2026-10-07';
select test.check((select count(*) from audit_log where action = 'reopen_month' and reason is not null) = 2, 'reopen audited with reason');
select close_month(:'mess', '2026-10-01') as oct2 \gset
select test.check(:'oct2' = :'oct', 'reclose reuses month row');
select test.check((select food_cost from month_member_summary where month_id = :'oct' and member_id = :'rahim') = round(12 * 1400 / 20.5, 2), 'snapshot refreshed on reclose');

-- Outsider and plain member cannot close/reopen; outsider sees no figures.
select test.act_as(:X);
select test.check((select count(*) from member_balances(:'mess', '2026-10-01', '2026-11-01')) = 0, 'outsider sees no balances');
select test.check((select count(*) from months) + (select count(*) from month_member_summary) = 0, 'outsider sees no months');
select test.expect_error(format($$select close_month(%L, '2026-11-01')$$, :'mess'), 'NOT_MANAGER');
select test.expect_error(format($$select reopen_month(%L, 'hack attempt')$$, :'oct'), 'NOT_MANAGER');
select test.act_as(null);
