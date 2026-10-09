-- Meal-off vs the automatic fill. A member's own off/on is an online RPC
-- (set_my_meal_off) with a hard deadline; the fill only touches days that
-- have ended, i.e. whose deadline has already passed. So: an off that landed
-- is never overwritten; an off that did not land is refused loudly
-- (CUTOFF_PASSED), never queued; a manager's late-synced edit beats an auto row.
\set M '''31b10000-0000-0000-0000-00000000000a'''
\set R '''31b10000-0000-0000-0000-00000000000b'''
\set K '''31b10000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:K);
select test.act_as(:M);
select create_mess('Race Mess', 'Manager') as mess \gset
select id as dinner from meal_types where mess_id = :'mess' and name = 'রাত' \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = (now() at time zone 'Asia/Dhaka')::date - 20 where mess_id = :'mess';
update messes set auto_meals = true where id = :'mess';
select ((now() at time zone 'Asia/Dhaka')::date - 1) as y \gset
-- Rahim's off landed in time; Karim has nothing.
insert into meal_entries (mess_id, member_id, meal_type_id, date, is_off) values (:'mess', :'rahim', :'dinner', :'y', true);
select auto_fill_meals(1);
select test.check((select is_off and count = 0 and source = 'app' from meal_entries where member_id = :'rahim' and date = :'y' and meal_type_id = :'dinner'),
                  'an off that landed is never overwritten');
select test.check((select count = 1 and source = 'auto' and not is_off from meal_entries where member_id = :'karim' and date = :'y' and meal_type_id = :'dinner'),
                  'Karim got an auto meal');

-- Karim now tries to switch it off: refused with CUTOFF_PASSED, row untouched.
select test.act_as(:K);
select test.expect_error(format($$select set_my_meal_off(%L, %L, %L, true)$$, :'mess', :'y', :'dinner'), 'CUTOFF_PASSED');
select test.act_as(null);
update messes set meal_off_lead_minutes = 120 where id = :'mess';
select test.act_as(:K);
select test.expect_error(format($$select set_my_meal_off(%L, %L, %L, true)$$, :'mess', :'y', :'dinner'), 'CUTOFF_PASSED');
select test.act_as(null);
select test.check((select count = 1 and source = 'auto' and not is_off from meal_entries where member_id = :'karim' and date = :'y' and meal_type_id = :'dinner'),
                  'a refused off leaves the auto row exactly as it was');

-- A manager's offline edit syncs late (an upsert): it replaces the auto row,
-- is no longer tagged auto, and a later fill never touches it.
select test.act_as(:M);
insert into meal_entries (mess_id, member_id, meal_type_id, date, count, is_off, source)
values (:'mess', :'karim', :'dinner', :'y', 0, true, 'app')
on conflict (member_id, date, meal_type_id) do update
  set count = excluded.count, is_off = excluded.is_off, source = excluded.source;
select test.act_as(null);
select test.check((select is_off and source = 'app' from meal_entries where member_id = :'karim' and date = :'y' and meal_type_id = :'dinner'), 'late-synced manager edit wins');
select auto_fill_meals(3);
select test.check((select is_off and source = 'app' from meal_entries where member_id = :'karim' and date = :'y' and meal_type_id = :'dinner'), 'and stays after another fill');

-- Invariant: the fill is only for ended days, and a meal-off deadline is
-- always before the end of its own day (serve_time < 24:00, lead >= 0), so a
-- valid off can never arrive after the fill has touched that day.
update meal_types set serve_time = '23:59:59' where id = :'dinner';
update messes set meal_off_lead_minutes = 0 where id = :'mess';
select test.check(meal_off_deadline(:'mess', :'y', :'dinner') < ((:'y'::date + 1)::timestamp at time zone 'Asia/Dhaka'), 'deadline (lead 0, 23:59:59) is inside its day');
update messes set meal_off_lead_minutes = null where id = :'mess';
select test.check(meal_off_deadline(:'mess', :'y', :'dinner') < (:'y'::date::timestamp at time zone 'Asia/Dhaka'), 'legacy deadline is the day before');
-- Today is never filled, and a member may still switch today's meal.
update meal_types set serve_time = '23:59:59' where id = :'dinner';
update messes set meal_off_lead_minutes = 0 where id = :'mess';
select test.check(not exists (select 1 from meal_entries where mess_id = :'mess' and date >= (now() at time zone 'Asia/Dhaka')::date and source = 'auto'), 'today not filled');
