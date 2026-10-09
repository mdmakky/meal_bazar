-- Auto-filled meals are not audited; prune_old_data drops 2-month-old
-- messages and audit rows but keeps month close/reopen and recent rows.
\set M '''29290000-0000-0000-0000-00000000000a'''
insert into auth.users (id) values (:M);
select test.act_as(:M);
select create_mess('Diet Mess', 'Manager') as mess \gset
select count(*) as before from audit_log where entity = 'meal_entries' \gset
select fill_meals_for_day(:'mess', current_date);
select test.check((select count(*) from meal_entries where mess_id = :'mess') > 0, 'filled');
select test.check((select count(*) from audit_log where entity = 'meal_entries') = :before, 'fill not audited');
update meal_entries set count = 0.5 where mess_id = :'mess';
select test.check((select count(*) from audit_log where entity = 'meal_entries') > :before, 'edits still audited');
select ensure_mess_group(:'mess') as grp \gset
select test.act_as(null);
insert into messages (thread_id, mess_id, sender_id, body, created_at)
values (:'grp', :'mess', :M, 'old', now() - interval '3 months'), (:'grp', :'mess', :M, 'new', now());
insert into audit_log (mess_id, actor_id, action, entity, at)
values (:'mess', :M, 'update', 'deposits', now() - interval '3 months'),
       (:'mess', :M, 'close_month', 'months', now() - interval '3 months');
select test.check((select (r ->> 'messages')::int = 1 and (r ->> 'audit')::int >= 1 from (select prune_old_data() r) x), 'pruned');
select test.check((select array_agg(body) = array['new'] from messages where thread_id = :'grp'), 'recent message kept');
select test.check(exists (select 1 from audit_log where action = 'close_month' and at < now() - interval '2 months'), 'month close kept');
select test.check((select count(*) from message_threads where id = :'grp') = 1, 'group thread kept');
select test.act_as(:M);
select test.expect_error('select prune_old_data()', 'permission denied');
select test.act_as(null);
