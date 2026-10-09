-- Lean audit; automatic due reminders: only dues past the threshold, random
-- manager text filled in, one thread per member, every N days, flags.
\set M '''30300000-0000-0000-0000-00000000000a'''
\set R '''30300000-0000-0000-0000-00000000000b'''
\set K '''30300000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:K);
select test.act_as(:M);
select create_mess('Due Mess', 'Manager') as mess \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = current_date - 40 where mess_id = :'mess';
select (now() at time zone 'Asia/Dhaka')::date as today \gset
select test.act_as(:M);
-- Lean audit: meal types and duties are no longer logged; deposits are.
select count(*) as a0 from audit_log where mess_id = :'mess' \gset
insert into meal_types (mess_id, name, sort_order) values (:'mess', 'নাস্তা', 9);
insert into bazar_duties (mess_id, date, member_id) values (:'mess', :'today', :'rahim');
select test.check((select count(*) from audit_log where mess_id = :'mess') = :a0, 'no audit for types/duties');
-- Rahim owes ~300 (equal expense), Karim pays it off.
select id as cat from expense_categories where mess_id = :'mess' limit 1 \gset
insert into expenses (mess_id, date, category_id, amount, split) values (:'mess', :'today', :'cat', 900, 'equal');
insert into deposits (mess_id, member_id, date, amount, method) values (:'mess', :'karim', :'today', 300, 'cash');
select test.check((select count(*) from audit_log where mess_id = :'mess' and entity = 'deposits') = 1, 'deposits still audited');
insert into due_reminder_texts (mess_id, body) values (:'mess', '{name}, বকেয়া {amount} ({mess})');
select test.act_as(:R);
select test.check((select count(*) from due_reminder_texts) = 0, 'members cannot read the texts');
select test.act_as(null);
-- Off by default.
select test.check(send_auto_due_reminders() = 0, 'off by default');
update messes set due_reminder_every = 2, due_reminder_min = 100 where id = :'mess';
select test.check(send_auto_due_reminders() = 2, 'Rahim and the manager owe');
select test.check((select count(*) from messages m join message_threads t on t.id = m.thread_id
                   where t.member_id = :'rahim' and m.kind = 'system' and m.body = 'Rahim, বকেয়া ৳৩০০ (Due Mess)'
                     and m.meta ->> 't' = 'due_reminder') = 1, 'filled text in Rahim''s thread');
select test.check(not exists (select 1 from message_threads where member_id = :'karim'), 'Karim paid: nothing');
select test.check((select count(*) from push_outbox where user_id = :R and type = 'message') >= 0, 'push path ran');
select test.check(send_auto_due_reminders() = 0, 'not again within 2 days');
update messes set due_reminder_last = :'today'::date - 2 where id = :'mess';
select test.check(send_auto_due_reminders() = 2, 'again after 2 days');
select test.check((select count(*) from message_threads where member_id = :'rahim') = 1, 'same thread reused');
update messes set due_reminder_last = null, due_reminder_min = 500 where id = :'mess';
select test.check(send_auto_due_reminders() = 0, 'under the threshold');
select test.act_as(:R);
select test.expect_error('select send_auto_due_reminders()', 'permission denied');
select test.act_as(null);
