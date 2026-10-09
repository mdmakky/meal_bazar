-- Mess group: one per mess, read/post by current members only (not pending,
-- left or outsiders); hide rules; pushes to every other active member with a
-- tag, honouring prefs and flags; direct threads unchanged.
\set M '''23230000-0000-0000-0000-00000000000a'''
\set U '''23230000-0000-0000-0000-00000000000b'''
\set V '''23230000-0000-0000-0000-00000000000c'''
\set P '''23230000-0000-0000-0000-00000000000d'''
\set L '''23230000-0000-0000-0000-00000000000e'''
\set X '''23230000-0000-0000-0000-00000000000f'''
\set I '''23230000-0000-0000-0000-000000000010'''
\set G1 '''23230000-0000-0000-0000-0000000000b1'''
\set G2 '''23230000-0000-0000-0000-0000000000b2'''
\set G3 '''23230000-0000-0000-0000-0000000000b3'''
insert into auth.users (id) values (:M), (:U), (:V), (:P), (:L), (:X), (:I);
update profiles set locale = 'en' where id = :V;

create function test.gob(p_user uuid) returns int language sql as $$
  select count(*)::int from public.push_outbox where user_id = p_user and type = 'group_message';
$$;

select test.act_as(:M);
select create_mess('Group Mess', 'Manager') as mess \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :U, 'Rahim');
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :V, 'Karim');
insert into mess_members (mess_id, user_id, display_name, status) values (:'mess', :P, 'Pending', 'pending');
insert into mess_members (mess_id, user_id, display_name, status, left_on) values (:'mess', :L, 'Left', 'left', current_date);
insert into mess_members (mess_id, user_id, display_name, status) values (:'mess', :I, 'Away', 'inactive');
select set_config('meal_bazar.trusted', '', false);
insert into device_tokens (token, user_id, platform)
values ('tok-grp-manager-1', :M, 'android'), ('tok-grp-member-01', :U, 'android'),
       ('tok-grp-member-02', :V, 'android'), ('tok-grp-pending-1', :P, 'android'),
       ('tok-grp-leftmem-1', :L, 'android'), ('tok-grp-inactive1', :I, 'android');
select test.act_as(:X);
select create_mess('Other Mess', 'Outsider') as other \gset

-- ── one group per mess, created lazily by any current member ───────────
select test.act_as(:U);
select ensure_mess_group(:'mess') as grp \gset
select test.act_as(:M);
select test.check(ensure_mess_group(:'mess') = :'grp', 'same group for everyone');
select test.act_as(:I);
select test.check(ensure_mess_group(:'mess') = :'grp', 'inactive member too');
select test.act_as(null);
select test.check((select count(*) from message_threads where mess_id = :'mess' and kind = 'group') = 1, 'one group');
select test.expect_error(format($$insert into message_threads (mess_id, kind, subject) values (%L, 'group', 'x')$$, :'mess'), 'message_threads_one_group');
select test.expect_error(format($$insert into message_threads (mess_id, kind, subject) values (%L, 'direct', 'x')$$, :'mess'), 'message_threads_kind_member');
select test.act_as(:P);
select test.expect_error(format($$select ensure_mess_group(%L)$$, :'mess'), 'NOT_MEMBER');
select test.act_as(:X);
select test.expect_error(format($$select ensure_mess_group(%L)$$, :'mess'), 'NOT_MEMBER');
select test.check(ensure_mess_group(:'other') <> :'grp', 'each mess its own group');

-- ── posting and pushes ─────────────────────────────────────────────────
select test.act_as(:U);
select post_message(:G1, :'grp', 'আজ রাতে মাছ হবে ' || repeat('x', 100));
select post_message(:G1, :'grp', 'retry');   -- offline retry
select test.act_as(null);
select test.check((select count(*) from messages where thread_id = :'grp') = 1, 'retry adds nothing');
select test.check(test.gob(:M) = 1 and test.gob(:V) = 1, 'every other active member');
select test.check(test.gob(:U) = 0, 'not the sender');
select test.check(test.gob(:P) + test.gob(:L) + test.gob(:I) = 0, 'not pending, left or inactive');
select test.check((select title = 'Group Mess · গ্রুপ' and body = 'Rahim: ' || left('আজ রাতে মাছ হবে ' || repeat('x', 100), 80)
                          and data ->> 'route' = '/more/messages/' || :'grp' and data ->> 'tag' = :'grp'
                   from push_outbox where user_id = :M and type = 'group_message'), 'bn title, 80-char body, route, tag');
select test.check((select title = 'Group Mess · group' from push_outbox where user_id = :V and type = 'group_message'), 'en title');
select test.check((select count(*) from push_outbox where type = 'message' and user_id in (:M, :U, :V)) = 0, 'no direct-message push');

-- ── visibility ─────────────────────────────────────────────────────────
select test.act_as(:V);
select test.check((select count(*) from messages where thread_id = :'grp') = 1, 'member reads');
select test.check((select kind = 'group' and member_id is null and is_unread and not last_hidden
                   from message_thread_feed where id = :'grp'), 'feed row');
select test.check(unread_thread_count(:'mess') = 0, 'group not counted as needing attention');
select post_message(:G2, :'grp', 'ঠিক আছে');
select mark_thread_read(:'grp');
select test.check(not (select is_unread from message_thread_feed where id = :'grp'), 'read');
select test.act_as(:I);
select test.check((select count(*) from messages where thread_id = :'grp') = 2, 'inactive reads');
select post_message(gen_random_uuid(), :'grp', 'I am away');
select test.act_as(:P);
select test.check((select count(*) from message_threads) + (select count(*) from messages)
                  + (select count(*) from message_thread_feed) = 0, 'pending sees nothing');
select test.expect_error(format($$select post_message(gen_random_uuid(), %L, 'x')$$, :'grp'), 'NOT_MEMBER');
select test.act_as(:L);
select test.check((select count(*) from message_threads) + (select count(*) from messages) = 0, 'left sees nothing');
select test.expect_error(format($$select post_message(gen_random_uuid(), %L, 'x')$$, :'grp'), 'NOT_MEMBER');
select test.expect_error(format($$select mark_thread_read(%L)$$, :'grp'), 'NOT_MEMBER');
select test.act_as(:X);
select test.check(not exists (select 1 from messages where thread_id = :'grp'), 'outsider sees nothing');
select test.expect_error(format($$select post_message(gen_random_uuid(), %L, 'x')$$, :'grp'), 'NOT_MEMBER');

-- ── hide: member own only, manager any, others not; audited ────────────
select test.act_as(:V);
select test.expect_error(format($$select hide_message(%L)$$, :G1), 'NOT_MANAGER');
select test.check(test.rows(format($$update messages set hidden_at = now() where id = %L$$, :G1)) = 0, 'no direct hide');
select hide_message(:G2);
select hide_message(:G2);   -- retry
select test.check((select body = '' and hidden_at is not null and hidden_by = :V from messages where id = :G2), 'own hidden');
select test.expect_error('select * from message_hidden_bodies', 'permission denied');
select test.act_as(:X);
select test.expect_error(format($$select hide_message(%L)$$, :G1), 'NOT_MEMBER');
select test.act_as(:M);
select hide_message(:G1);
select test.act_as(null);
select test.check((select body from message_hidden_bodies where message_id = :G1) like 'আজ রাতে মাছ হবে%', 'text kept server-side');
select test.check((select count(*) from audit_log where action = 'hide_message' and mess_id = :'mess') = 2, 'audited once each');
select test.check(not exists (select 1 from audit_log where action = 'hide_message' and old::text like '%মাছ%'), 'audit has no text');

-- Direct threads stay append-only: nobody hides there.
select test.act_as(:U);
select start_thread(:G3, :'mess', 'Direct', 'private') ;
select id as dmsg from messages where thread_id = :G3 \gset
select test.expect_error(format($$select hide_message(%L)$$, :'dmsg'), 'NOT_MANAGER');
select test.act_as(:M);
select test.expect_error(format($$select hide_message(%L)$$, :'dmsg'), 'NOT_MANAGER');
select test.check(unread_thread_count(:'mess') = 1, 'direct thread still counted');
select test.act_as(:V);
select test.check(not exists (select 1 from message_threads where id = :G3), 'direct thread still private');
select test.act_as(null);
select test.check((select count(*) from push_outbox where type = 'message' and user_id = :M and not data ? 'tag') = 1, 'direct push untagged');

-- ── prefs and flags ────────────────────────────────────────────────────
update profiles set notification_prefs = '{"group_message": false}' where id = :V;
select test.act_as(:M);
select post_message(gen_random_uuid(), :'grp', 'muted?');
select test.act_as(null);
select test.check(test.gob(:V) = 2 and test.gob(:U) = 3, 'muted member skipped, others notified');
update profiles set notification_prefs = '{}' where id = :V;
update platform_config set value = value || '{"mess_group": false}' where key = 'features';
select test.act_as(:M);
select post_message(gen_random_uuid(), :'grp', 'group flag off');
select test.act_as(null);
select test.check(test.gob(:U) = 3, 'mess_group flag off: not queued');
update platform_config set value = value - 'mess_group' || '{"messages": false}' where key = 'features';
select test.act_as(:M);
select post_message(gen_random_uuid(), :'grp', 'messages off');
select test.act_as(null);
select test.check(test.gob(:U) = 3, 'messages flag off: not queued');
update platform_config set value = value - 'messages' || '{"push": false}' where key = 'features';
select test.act_as(:M);
select post_message(gen_random_uuid(), :'grp', 'push off');
select test.act_as(null);
select test.check(test.gob(:U) = 3, 'push flag off: not queued');
update platform_config set value = value - 'push' where key = 'features';
select test.check((platform_config_defaults() -> 'features' ->> 'mess_group')::boolean, 'mess_group in the defaults');
select test.check((platform_config_defaults() -> 'features' ->> 'messages')::boolean, 'earlier defaults kept');

-- ── suspension: group still opens, writes and hides are blocked ────────
insert into platform_admins (user_id) values (:X);
select test.act_as(:X);
select admin_set_mess_suspended(:'mess', true, 'test');
select test.act_as(:U);
select test.check(ensure_mess_group(:'mess') = :'grp', 'opens while suspended');
select test.expect_error(format($$select post_message(gen_random_uuid(), %L, 'x')$$, :'grp'), 'MESS_SUSPENDED');
select test.act_as(:X);
select admin_set_mess_suspended(:'mess', false, null);
select test.act_as(null);
