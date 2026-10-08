-- Notices: manager posts, member reads + marks read, member cannot post,
-- outsider sees nothing, expired/deleted hidden from the feed, audited.
\set M '''13130000-0000-0000-0000-00000000000a'''
\set U '''13130000-0000-0000-0000-00000000000b'''
\set X '''13130000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:U), (:X);

select test.act_as(:M);
select create_mess('Notice Mess', 'Manager') as mess \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :U, 'Rahim') returning id as rahim \gset
select set_config('meal_bazar.trusted', '', false);
select test.act_as(:X);
select create_mess('Other Mess', 'Outsider') as other \gset
select id as xmem from mess_members where mess_id = :'other' and user_id = :X \gset

-- Manager posts: a live, a pinned, an expired and a deleted notice.
select test.act_as(:M);
insert into announcements (mess_id, title, body) values (:'mess', 'পানি বন্ধ', 'কাল সকালে') returning id as n1 \gset
insert into announcements (mess_id, title, pinned) values (:'mess', 'ভাড়া দিন', true) returning id as n2 \gset
insert into announcements (mess_id, title, expires_at) values (:'mess', 'পুরনো', now() - interval '1 hour');
insert into announcements (mess_id, title) values (:'mess', 'মুছে ফেলা') returning id as n4 \gset
select test.check(test.rows(format($$update announcements set deleted_at = now() where id = %L$$, :'n4')) = 1, 'manager soft-deletes');
select test.check(test.rows(format($$update announcements set title = 'পানি বন্ধ!' where id = %L$$, :'n1')) = 1, 'manager edits');
select test.expect_error(format($$insert into announcements (mess_id, title) values (%L, '  ')$$, :'mess'), 'check');
select test.expect_error(format($$insert into announcements (mess_id, title) values (%L, %L)$$, :'mess', repeat('x', 81)), 'check');
select test.expect_error(format($$insert into announcements (mess_id, title, body) values (%L, 'ok', %L)$$, :'mess', repeat('x', 1001)), 'check');

-- Member reads the feed: expired and deleted are hidden, nothing read yet.
select test.act_as(:U);
select test.check((select count(*) from announcement_feed) = 2, 'feed hides expired + deleted');
select test.check((select count(*) from announcements) = 4, 'raw table still readable by members');
select test.check((select count(*) from announcement_feed where is_read) = 0, 'nothing read yet');

-- Member marks read (upsert twice is fine) and the flag shows.
insert into announcement_reads (announcement_id, member_id) values (:'n1', :'rahim');
insert into announcement_reads (announcement_id, member_id) values (:'n1', :'rahim')
  on conflict (announcement_id, member_id) do update set read_at = now();
select test.check((select is_read from announcement_feed where id = :'n1'), 'member sees own read flag');

-- Member cannot post, edit, delete, or mark read for someone else.
select test.expect_error(format($$insert into announcements (mess_id, title) values (%L, 'hi')$$, :'mess'), 'row-level security');
select test.check(test.rows(format($$update announcements set title = 'x' where id = %L$$, :'n1')) = 0, 'member cannot edit');
select test.check(test.rows(format($$delete from announcements where id = %L$$, :'n1')) = 0, 'member cannot delete');
select id as mgr from mess_members where mess_id = :'mess' and role = 'manager' \gset
select test.expect_error(format($$insert into announcement_reads (announcement_id, member_id) values (%L, %L)$$, :'n2', :'mgr'), 'row-level security');

-- Manager's read flag is their own, not Rahim's.
select test.act_as(:M);
select test.check((select not is_read from announcement_feed where id = :'n1'), 'read flag is per user');
select test.check((select count(*) from announcement_reads) = 1, 'manager sees who read');

-- Outsider sees nothing and cannot mark read with their own member id.
select test.act_as(:X);
select test.check((select count(*) from announcements) + (select count(*) from announcement_feed)
                  + (select count(*) from announcement_reads) = 0, 'outsider sees nothing');
select test.expect_error(format($$insert into announcement_reads (announcement_id, member_id) values (%L, %L)$$, :'n2', :'xmem'), 'row-level security');
select test.expect_error(format($$insert into announcements (mess_id, title) values (%L, 'hi')$$, :'mess'), 'row-level security');

select test.act_as(null);
select test.check((select count(*) from audit_log where entity = 'announcements') = 6, 'notices audited');
