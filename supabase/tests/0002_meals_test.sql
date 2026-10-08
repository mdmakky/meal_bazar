-- Meals: defaults, constraints, ½ meals, guests, weights, off, fill, RLS.
\set M '''11111111-0000-0000-0000-00000000000a'''
\set R '''11111111-0000-0000-0000-00000000000b'''
\set X '''11111111-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:X);

select test.act_as(:M);
select create_mess('Meal Mess', 'Manager') as mess \gset
select test.check((select count(*) from meal_types where mess_id = :'mess') = 3, 'default meal types seeded');
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
select id as dinner from meal_types where mess_id = :'mess' and name = 'রাত' \gset
select id as bf from meal_types where mess_id = :'mess' and name = 'সকাল' \gset
-- Pin the manager's join date so the fixture doesn't depend on the machine clock.
update mess_members set joined_on = '2026-10-01' where mess_id = :'mess' and user_id = :M;
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'Rahim', '2026-10-01') returning id as rahim \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'Karim', '2026-10-01') returning id as karim \gset

-- Constraints.
select test.expect_error(format($$insert into meal_entries (mess_id, member_id, meal_type_id, date, count) values (%L, %L, %L, '2026-10-02', 0.3)$$, :'mess', :'rahim', :'lunch'), 'check');
select test.expect_error(format($$insert into meal_entries (mess_id, member_id, meal_type_id, date, count) values (%L, %L, %L, '2026-10-02', -1)$$, :'mess', :'rahim', :'lunch'), 'check');
select test.expect_error(format($$insert into meal_entries (mess_id, member_id, meal_type_id, date, guest_count) values (%L, %L, %L, '2026-10-02', 21)$$, :'mess', :'rahim', :'lunch'), 'check');

-- PRODUCT_RULES §3 fixture: Rahim 10 + 2 guest, Karim 8.5 → 12 and 8.5 billable.
insert into meal_entries (mess_id, member_id, meal_type_id, date, count, guest_count)
select :'mess', :'rahim', :'lunch', d::date, 1, case when d = '2026-10-01' then 2 else 0 end
from generate_series('2026-10-01'::date, '2026-10-10', '1 day') d;
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
select :'mess', :'karim', :'lunch', d::date, case when d = '2026-10-01' then 0.5 else 1 end
from generate_series('2026-10-01'::date, '2026-10-09', '1 day') d;
select test.check((select meals from member_meal_totals(:'mess', '2026-10-01', '2026-11-01') where member_id = :'rahim') = 12, 'rahim 10 + 2 guests = 12');
select test.check((select guest_meals from member_meal_totals(:'mess', '2026-10-01', '2026-11-01') where member_id = :'rahim') = 2, 'rahim guest meals = 2');
select test.check((select meals from member_meal_totals(:'mess', '2026-10-01', '2026-11-01') where member_id = :'karim') = 8.5, 'karim 8.5 (½ meal)');
select test.check((select count(*) from member_meal_totals(:'mess', '2026-10-05', '2026-10-06')) = 2, 'range is [from, to)');

-- Off forces own count to 0 but keeps guests; weights apply.
update meal_entries set is_off = true, guest_count = 1 where member_id = :'karim' and date = '2026-10-09';
select test.check((select count = 0 from meal_entries where member_id = :'karim' and date = '2026-10-09'), 'off zeroes own meal');
update meal_types set enabled = true where id = :'bf';
insert into meal_entries (mess_id, member_id, meal_type_id, date, count) values (:'mess', :'rahim', :'bf', '2026-10-11', 1);
select test.check((select meals from member_meal_totals(:'mess', '2026-10-11', '2026-10-12') where member_id = :'rahim') = 0.5, 'breakfast weight 0.5');

-- Entries must belong to the same mess (composite FK).
select create_mess('Other Mess', 'Manager') as other \gset
select id as other_lunch from meal_types where mess_id = :'other' and name = 'দুপুর' \gset
select test.expect_error(format($$insert into meal_entries (mess_id, member_id, meal_type_id, date) values (%L, %L, %L, '2026-10-02')$$, :'other', :'rahim', :'other_lunch'), 'foreign key');
select test.expect_error(format($$insert into meal_entries (mess_id, member_id, meal_type_id, date) values (%L, %L, %L, '2026-10-02')$$, :'mess', :'rahim', :'other_lunch'), 'foreign key');

-- Fill today copies yesterday (Karim off → guest not copied, count 0), defaults to 1, idempotent.
select test.check(fill_meals_for_day(:'mess', '2026-10-10') = 8, 'fill creates missing rows only (3 members × 3 types − 1 existing)');
select test.check(fill_meals_for_day(:'mess', '2026-10-10') = 0, 'fill is idempotent');
select test.check((select count from meal_entries where member_id = :'karim' and date = '2026-10-10' and meal_type_id = :'lunch') = 0, 'fill copies yesterday''s 0');
select test.check((select count from meal_entries where member_id = :'mgr' and date = '2026-10-10' and meal_type_id = :'dinner') = 1, 'fill defaults to 1');

-- RLS: outsider sees nothing; plain member cannot write.
select test.act_as(:X);
select test.check((select count(*) from meal_entries) = 0, 'outsider cannot read meals');
select test.check((select count(*) from member_meal_totals(:'mess', '2026-10-01', '2026-11-01')) = 0, 'outsider gets no totals');
select test.expect_error(format($$select fill_meals_for_day(%L, '2026-10-12')$$, :'mess'), 'NOT_MANAGER');
select test.act_as(:M);
select create_invite(:'mess') as code \gset
select test.act_as(:R);
select join_mess(:'code', 'Rasel') as rasel \gset
select test.act_as(:M);
update mess_members set status = 'active' where id = :'rasel';
select test.act_as(:R);
select test.check((select count(*) from meal_entries) > 0, 'member reads meals');
select test.check(test.rows($$update meal_entries set count = 5$$) = 0, 'member cannot edit meals');
select test.expect_error(format($$insert into meal_entries (mess_id, member_id, meal_type_id, date) values (%L, %L, %L, '2026-10-12')$$, :'mess', :'rasel', :'lunch'), 'row-level security');
select test.act_as(null);
