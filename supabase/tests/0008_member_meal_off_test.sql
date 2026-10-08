-- Member meal-off: own row only, before the cutoff, active members, closed-month guard, audit.
\set M '''88888888-0000-0000-0000-00000000000a'''
\set R '''88888888-0000-0000-0000-00000000000b'''
\set P '''88888888-0000-0000-0000-00000000000c'''
\set X '''88888888-0000-0000-0000-00000000000d'''
insert into auth.users (id) values (:M), (:R), (:P), (:X);

select test.act_as(:M);
select create_mess('Off Mess', 'Manager') as mess \gset
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
select id as bf from meal_types where mess_id = :'mess' and name = 'সকাল' \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select create_invite(:'mess') as code \gset
select test.act_as(:R);
select join_mess(:'code', 'Rahim') as rahim \gset
select test.act_as(:P);
select join_mess(:'code', 'Pending') as pend \gset
select test.act_as(:M);
update mess_members set status = 'active' where id = :'rahim';
-- Close a far-future month first (no earlier activity, so ordering allows it).
select close_month(:'mess', '2099-01-15') as jan \gset
-- Manager has an existing guest row for Rahim; turning off keeps guests.
insert into meal_entries (mess_id, member_id, meal_type_id, date, count, guest_count)
values (:'mess', :'rahim', :'lunch', '2099-03-02', 1, 2);
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
values (:'mess', :'mgr', :'lunch', '2099-03-01', 1);

-- Member turns own meal off (new row) and back on, before the cutoff.
select test.act_as(:R);
select set_my_meal_off(:'mess', '2099-03-01', :'lunch', true);
select test.check((select is_off and count = 0 and source = 'app' from meal_entries
                   where member_id = :'rahim' and date = '2099-03-01' and meal_type_id = :'lunch'), 'off creates own row, count 0');
select set_my_meal_off(:'mess', '2099-03-01', :'lunch', false);
select test.check((select not is_off and count = 1 from meal_entries
                   where member_id = :'rahim' and date = '2099-03-01' and meal_type_id = :'lunch'), 'back on: count 1');
select set_my_meal_off(:'mess', '2099-03-02', :'lunch', true);
select test.check((select is_off and count = 0 and guest_count = 2 from meal_entries
                   where member_id = :'rahim' and date = '2099-03-02'), 'off keeps guests');

-- Only the caller's own row changes; the manager's row on the same day is untouched.
select test.check((select not is_off and count = 1 from meal_entries
                   where member_id = :'mgr' and date = '2099-03-01'), 'other member untouched');
select test.check((select count(*) from meal_entries where date between '2099-03-01' and '2099-03-02') = 3, 'no extra rows');

-- Audit row written with the member as actor.
select test.check((select count(*) from audit_log where entity = 'meal_entries' and actor_id = :R) = 3, 'audit row per change by member');

-- After the cutoff (past date / today) refused.
select test.expect_error(format($$select set_my_meal_off(%L, '2020-01-01', %L, true)$$, :'mess', :'lunch'), 'CUTOFF_PASSED');
select test.expect_error(format($$select set_my_meal_off(%L, current_date, %L, true)$$, :'mess', :'lunch'), 'CUTOFF_PASSED');
-- Disabled / foreign meal type refused.
select test.expect_error(format($$select set_my_meal_off(%L, '2099-03-01', %L, true)$$, :'mess', :'bf'), 'MEAL_TYPE_INVALID');
-- Closed month refused by the guard trigger.
select test.expect_error(format($$select set_my_meal_off(%L, '2099-01-20', %L, true)$$, :'mess', :'lunch'), 'MONTH_CLOSED');
-- Direct writes stay manager-only.
select test.expect_error(format($$insert into meal_entries (mess_id, member_id, meal_type_id, date) values (%L, %L, %L, '2099-03-05')$$, :'mess', :'rahim', :'lunch'), 'row-level security');

-- Pending member and outsider refused.
select test.act_as(:P);
select test.expect_error(format($$select set_my_meal_off(%L, '2099-03-01', %L, true)$$, :'mess', :'lunch'), 'NOT_MEMBER');
select test.act_as(:X);
select test.expect_error(format($$select set_my_meal_off(%L, '2099-03-01', %L, true)$$, :'mess', :'lunch'), 'NOT_MEMBER');
select test.act_as(null);
