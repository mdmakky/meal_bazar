select set_config('meal_bazar.today', '2099-12-31', false);
-- A correction within 10 minutes updates the actor's own previous log line.
\set M '''39390000-0000-0000-0000-00000000000a'''
\set R '''39390000-0000-0000-0000-00000000000b'''
insert into auth.users (id) values (:M), (:R);
select test.act_as(:M);
select create_mess('Audit Mess', 'Manager') as mess \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
select set_config('meal_bazar.trusted', '', false);
select id as mt from meal_types where mess_id = :'mess' order by created_at limit 1 \gset
select (now() at time zone 'Asia/Dhaka')::date as today \gset
delete from audit_log where mess_id = :'mess';

-- 0 → ½ → 1 : one line, "added 1"
select test.act_as(:M);
insert into meal_entries (id, mess_id, member_id, meal_type_id, date, count)
values ('39390000-0000-0000-0000-0000000000e1', :'mess', :'rahim', :'mt', :'today', 0.5);
update meal_entries set count = 1 where id = '39390000-0000-0000-0000-0000000000e1';
select test.act_as(null);
select test.check((select count(*) = 1 and bool_and(action = 'insert' and (new ->> 'count')::numeric = 1)
                   from audit_log where entity = 'meal_entries' and mess_id = :'mess'), 'added ½ then 1 is one line: added 1');

-- someone else, or a different row, still gets their own line
select test.act_as(:M);
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
values (:'mess', :'rahim', :'mt', (:'today'::date - 1), 1);
select test.act_as(null);
select test.check((select count(*) = 2 from audit_log where entity = 'meal_entries' and mess_id = :'mess'), 'another row has its own line');

-- an older line (over 10 minutes) is not rewritten
update audit_log set at = now() - interval '11 minutes' where entity = 'meal_entries' and mess_id = :'mess';
select test.act_as(:M);
update meal_entries set count = 2 where id = '39390000-0000-0000-0000-0000000000e1';
select test.act_as(null);
select test.check((select count(*) = 3 from audit_log where entity = 'meal_entries' and mess_id = :'mess'), 'past 10 minutes: a new line');

-- and back to where it started within the window: the update line disappears
select test.act_as(:M);
update meal_entries set count = 1 where id = '39390000-0000-0000-0000-0000000000e1';
select test.act_as(null);
select test.check((select count(*) = 2 from audit_log where entity = 'meal_entries' and mess_id = :'mess'), 'undone within the window: no line');

-- soft deletes are never merged
select test.act_as(:M);
insert into bazars (id, mess_id, date, amount, buyer_member_id) values ('39390000-0000-0000-0000-0000000000b1', :'mess', :'today', 100, :'rahim');
update bazars set amount = 120 where id = '39390000-0000-0000-0000-0000000000b1';
update bazars set deleted_at = now() where id = '39390000-0000-0000-0000-0000000000b1';
select test.act_as(null);
select test.check((select count(*) = 2 and bool_or((new ->> 'deleted_at') is not null) from audit_log
                   where entity = 'bazars' and mess_id = :'mess'), 'insert (merged edit) + a separate delete line');
