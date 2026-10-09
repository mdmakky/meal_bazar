-- Messages: a member's threads are theirs + the managers'; outsiders see
-- nothing; messages are append-only; status rules; unread counts; pushes go
-- to the other side honouring prefs and flags; idempotent retries.
\set M '''22220000-0000-0000-0000-00000000000a'''
\set U '''22220000-0000-0000-0000-00000000000b'''
\set V '''22220000-0000-0000-0000-00000000000c'''
\set X '''22220000-0000-0000-0000-00000000000d'''
\set M2 '''22220000-0000-0000-0000-00000000000e'''
\set T1 '''22220000-0000-0000-0000-0000000000a1'''
\set T2 '''22220000-0000-0000-0000-0000000000a2'''
\set T3 '''22220000-0000-0000-0000-0000000000a3'''
insert into auth.users (id) values (:M), (:U), (:V), (:X), (:M2);
update profiles set locale = 'en' where id = :U;

create function test.ob(p_user uuid) returns int language sql as $$
  select count(*)::int from public.push_outbox where user_id = p_user and type = 'message';
$$;

select test.act_as(:M);
select create_mess('Msg Mess', 'Manager') as mess \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :U, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :V, 'Karim') returning id as karim \gset
insert into mess_members (mess_id, user_id, display_name, role) values (:'mess', :M2, 'Second', 'manager');
select set_config('meal_bazar.trusted', '', false);
insert into device_tokens (token, user_id, platform)
values ('tok-msg-manager-1', :M, 'android'), ('tok-msg-member-01', :U, 'android'),
       ('tok-msg-member-02', :V, 'android'), ('tok-msg-manager-2', :M2, 'android');
select test.act_as(:X);
select create_mess('Other Mess', 'Outsider') as other \gset

-- ── a member reports a problem about a deposit ──────────────────────────
select test.act_as(:U);
select test.check(start_thread(:T1, :'mess', 'সমস্যা: জমা ৳500', 'এই তথ্যটি ভুল মনে হচ্ছে',
                               'deposit', gen_random_uuid(), 'জমা ৳500, 5 Oct') = :T1, 'thread id returned');
select start_thread(:T1, :'mess', 'সমস্যা: জমা ৳500', 'এই তথ্যটি ভুল মনে হচ্ছে');   -- offline retry
select test.check((select count(*) from messages where thread_id = :T1) = 1, 'retry adds nothing');
select test.expect_error(format($$select start_thread(gen_random_uuid(), %L, '  ', 'x')$$, :'mess'), 'check');
select test.expect_error(format($$select start_thread(gen_random_uuid(), %L, 'x', %L)$$, :'mess', repeat('x', 1001)), 'check');
select test.expect_error(format($$select start_thread(gen_random_uuid(), %L, %L, 'x')$$, :'mess', repeat('x', 81)), 'check');
select test.expect_error(format($$select start_thread(gen_random_uuid(), %L, 'x', 'y', 'rent')$$, :'mess'), 'check');
-- A member cannot open a thread on someone else's behalf.
select test.expect_error(format($$select start_thread(gen_random_uuid(), %L, 'x', 'y', p_member => %L)$$, :'mess', :'karim'), 'NOT_MANAGER');
select test.expect_error(format($$select start_thread(gen_random_uuid(), %L, 'x', 'y')$$, :'other'), 'NOT_MEMBER');

select test.act_as(null);
select test.check(test.ob(:M) = 1 and test.ob(:M2) = 1, 'member message → every manager');
select test.check(test.ob(:U) + test.ob(:V) = 0, 'not the sender, not other members');
select test.check((select title = 'বার্তা: সমস্যা: জমা ৳500' and body = 'Rahim: এই তথ্যটি ভুল মনে হচ্ছে'
                          and data ->> 'route' = '/more/messages/' || :T1
                   from push_outbox where user_id = :M and type = 'message'), 'bn text + route');

-- ── visibility ──────────────────────────────────────────────────────────
select test.act_as(:V);
select start_thread(:T2, :'mess', 'Karim asks', 'hello');
select test.check((select count(*) from message_threads) = 1, 'member sees only own thread');
select test.check((select count(*) from messages) = 1 and (select count(*) from message_thread_feed) = 1, 'and only own messages');
select test.expect_error(format($$select post_message(gen_random_uuid(), %L, 'sneaky')$$, :T1), 'NOT_MEMBER');
select test.expect_error(format($$select mark_thread_read(%L)$$, :T1), 'NOT_MEMBER');
select test.act_as(:X);
select test.check((select count(*) from message_threads) + (select count(*) from messages)
                  + (select count(*) from message_thread_feed) = 0, 'outsider sees nothing');
select test.expect_error(format($$select post_message(gen_random_uuid(), %L, 'hi')$$, :T1), 'NOT_MEMBER');
select test.act_as(:M);
select test.check((select count(*) from message_threads) = 2, 'manager sees every thread');
select test.check((select member_name = 'Rahim' and last_body = 'এই তথ্যটি ভুল মনে হচ্ছে' and is_unread and ref_type = 'deposit'
                   from message_thread_feed where id = :T1), 'feed row');
select test.check(unread_thread_count(:'mess') = 2, 'manager: two unread');

-- ── append-only and no direct writes ───────────────────────────────────
select test.act_as(:U);
select test.check(test.rows(format($$update messages set body = 'edited' where thread_id = %L$$, :T1)) = 0, 'no edits');
select test.check(test.rows(format($$delete from messages where thread_id = %L$$, :T1)) = 0, 'no deletes');
select test.check(test.rows(format($$update message_threads set status = 'resolved' where id = %L$$, :T1)) = 0, 'no direct status');
select test.expect_error(format($$insert into messages (thread_id, mess_id, sender_id, body) values (%L, %L, %L, 'x')$$, :T1, :'mess', :U), 'row-level security');
select test.expect_error(format($$insert into message_threads (mess_id, member_id, subject) values (%L, %L, 'x')$$, :'mess', :'rahim'), 'row-level security');
select test.act_as(:M);
select test.check(test.rows(format($$delete from messages where thread_id = %L$$, :T1)) = 0, 'manager cannot delete either');

-- ── manager replies → the member only; read marks ──────────────────────
select mark_thread_read(:T1);
select test.check(unread_thread_count(:'mess') = 1, 'read clears unread');
select post_message('22220000-0000-0000-0000-0000000000b1', :T1, 'ঠিক করে দিচ্ছি');
select post_message('22220000-0000-0000-0000-0000000000b1', :T1, 'ঠিক করে দিচ্ছি');   -- retry
select test.check(unread_thread_count(:'mess') = 1, 'my own reply is not unread');
select test.act_as(null);
select test.check((select count(*) from messages where thread_id = :T1) = 2, 'retry adds nothing');
select test.check(test.ob(:U) = 1 and test.ob(:M2) = 2 and test.ob(:V) = 0, 'manager reply → the member only');
select test.check((select title = 'Message: সমস্যা: জমা ৳500' and body = 'Manager: ঠিক করে দিচ্ছি'
                   from push_outbox where user_id = :U and type = 'message'), 'en text for an en profile');
select test.act_as(:U);
select test.check(unread_thread_count(:'mess') = 1, 'member: reply unread');
select mark_thread_read(:T1);
select test.check(unread_thread_count(:'mess') = 0, 'member: read');
select test.check((select count(*) from message_reads) = 1, 'only own read rows');

-- ── status: managers resolve/reopen; the member may only reopen ────────
select test.expect_error(format($$select set_thread_status(%L, 'resolved')$$, :T1), 'NOT_MANAGER');
select test.act_as(:M);
select set_thread_status(:T1, 'resolved');
select test.expect_error(format($$select set_thread_status(%L, 'closed')$$, :T1), 'check');
select test.act_as(:U);
select test.check((select status = 'resolved' from message_threads where id = :T1), 'resolved');
select set_thread_status(:T1, 'open');
select test.check((select status = 'open' from message_threads where id = :T1), 'member reopened');
select test.act_as(:M);
select set_thread_status(:T1, 'resolved');
select test.act_as(:U);
select post_message(gen_random_uuid(), :T1, 'still wrong');
select test.check((select status = 'open' from message_threads where id = :T1), 'member writing reopens');

-- ── manager starts a thread with a member ──────────────────────────────
select test.act_as(:M);
select start_thread(:T3, :'mess', 'ভাড়া', 'কাল ভাড়া দিও', p_member => :'karim');
select test.act_as(:V);
select test.check((select count(*) from message_threads) = 2, 'member sees the thread written to them');
select test.act_as(:U);
select test.check(not exists (select 1 from message_threads where id = :T3), 'others do not');
select test.act_as(null);
select test.check(test.ob(:V) = 1, 'manager-started thread pushes the member');

-- ── prefs and flags ────────────────────────────────────────────────────
update profiles set notification_prefs = '{"message": false}' where id = :V;
select test.act_as(:M);
select post_message(gen_random_uuid(), :T3, 'again');
select test.act_as(null);
select test.check(test.ob(:V) = 1, 'type off: not queued');
update profiles set notification_prefs = '{}' where id = :V;
update platform_config set value = value || '{"push": false}' where key = 'features';
select test.act_as(:M);
select post_message(gen_random_uuid(), :T3, 'push off');
select test.act_as(null);
select test.check(test.ob(:V) = 1, 'push flag off: not queued');
update platform_config set value = value - 'push' || '{"messages": false}' where key = 'features';
select test.act_as(:M);
select post_message(gen_random_uuid(), :T3, 'messages off');
select test.act_as(null);
select test.check(test.ob(:V) = 1, 'messages flag off: not queued');
update platform_config set value = value - 'messages' where key = 'features';
select test.check((platform_config_defaults() -> 'features' ->> 'messages')::boolean, 'messages in the defaults');
select test.check((platform_config_defaults() -> 'features' ->> 'push')::boolean, 'earlier defaults kept');

-- ── suspension blocks writes; nothing queued ───────────────────────────
select count(*) as before from push_outbox \gset
insert into platform_admins (user_id) values (:X);
select test.act_as(:X);
select admin_set_mess_suspended(:'mess', true, 'test');
select test.act_as(:U);
select test.expect_error(format($$select post_message(gen_random_uuid(), %L, 'x')$$, :T1), 'MESS_SUSPENDED');
select test.expect_error(format($$select start_thread(gen_random_uuid(), %L, 'x', 'y')$$, :'mess'), 'MESS_SUSPENDED');
select test.check((select count(*) from messages where thread_id = :T1) = 3, 'reads still work');
select test.act_as(:X);
select admin_set_mess_suspended(:'mess', false, null);
select test.act_as(null);
select test.check((select count(*) from push_outbox) = :before, 'nothing queued for rejected writes');
