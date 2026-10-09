-- Bazar duty: rotation order, skip existing dates, member marks own done only, outsider nothing.
\set M '''14141414-0000-0000-0000-00000000000a'''
\set R '''14141414-0000-0000-0000-00000000000b'''
\set K '''14141414-0000-0000-0000-00000000000c'''
\set X '''14141414-0000-0000-0000-00000000000d'''
insert into auth.users (id) values (:M), (:R), (:K), (:X);

select test.act_as(:M);
select create_mess('Duty Mess', 'Manager') as mess \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select create_invite(:'mess') as code \gset
select test.act_as(:R);
select join_mess(:'code', 'Rahim') as rahim \gset
select test.act_as(:K);
select join_mess(:'code', 'Karim') as karim \gset
select test.act_as(:M);
update mess_members set status = 'active' where id in (:'rahim', :'karim');

-- An existing duty on day 3 is kept and skipped.
insert into bazar_duties (mess_id, date, member_id) values (:'mess', '2099-05-03', :'mgr');

-- 7 days every 1 day → 6 new rows; day 3 is skipped and the order continues on day 4.
select test.check(generate_duty_rotation(:'mess', '2099-05-01', 7,
  array[:'rahim', :'karim', :'mgr']::uuid[]) = 6, 'six created');
select test.check((select string_agg(m.display_name, ',' order by d.date)
                   from bazar_duties d join mess_members m on m.id = d.member_id
                   where d.mess_id = :'mess') = 'Rahim,Karim,Manager,Manager,Rahim,Karim,Manager',
                  'round-robin order with day 3 kept');
-- Re-running creates nothing (every date taken).
select test.check(generate_duty_rotation(:'mess', '2099-05-01', 7, array[:'rahim']::uuid[]) = 0, 'idempotent');
-- Every 3 days over 10 days → 05-20, 05-23, 05-26, 05-29.
select test.check(generate_duty_rotation(:'mess', '2099-05-20', 10, array[:'karim', :'rahim']::uuid[], 3) = 4, 'every 3 days');
select test.check((select member_id from bazar_duties where mess_id = :'mess' and date = '2099-05-26') = :'karim', 'every-3 order');
select test.check((select count(*) from audit_log where entity = 'bazar_duties') = 0, 'duties not audited (0030)');

-- Bad input.
select test.expect_error(format($$select generate_duty_rotation(%L, '2099-06-01', 5, '{}'::uuid[])$$, :'mess'), 'INVALID_ROTATION');
select test.expect_error(format($$select generate_duty_rotation(%L, '2099-06-01', 5, array[%L]::uuid[])$$, :'mess', :X), 'INVALID_ROTATION');

select id as r1 from bazar_duties where mess_id = :'mess' and date = '2099-05-01' \gset
select id as k2 from bazar_duties where mess_id = :'mess' and date = '2099-05-02' \gset

-- Member: reads, marks own done (and undone), not others; cannot write directly or generate.
select test.act_as(:R);
select test.check((select count(*) from bazar_duties where mess_id = :'mess') = 11, 'member reads roster');
select mark_my_duty_done(:'r1');
select test.check((select done from bazar_duties where id = :'r1'), 'own marked done');
select mark_my_duty_done(:'r1', false);
select test.check((select not done from bazar_duties where id = :'r1'), 'own unmarked');
select mark_my_duty_done(:'r1');
select test.expect_error(format($$select mark_my_duty_done(%L)$$, :'k2'), 'NOT_YOUR_DUTY');
select test.check((select not done from bazar_duties where id = :'k2'), 'other untouched');
select test.check(test.rows(format($$update bazar_duties set done = true where id = %L$$, :'k2')) = 0, 'direct update blocked');
select test.expect_error(format($$insert into bazar_duties (mess_id, date, member_id) values (%L, '2099-07-01', %L)$$, :'mess', :'rahim'), 'row-level security');
select test.expect_error(format($$select generate_duty_rotation(%L, '2099-07-01', 3, array[%L]::uuid[])$$, :'mess', :'rahim'), 'NOT_MANAGER');

-- Outsider: sees nothing, can do nothing.
select test.act_as(:X);
select test.check((select count(*) from bazar_duties) = 0, 'outsider reads nothing');
select test.expect_error(format($$select mark_my_duty_done(%L)$$, :'k2'), 'NOT_YOUR_DUTY');
select test.expect_error(format($$select generate_duty_rotation(%L, '2099-07-01', 3, array[%L]::uuid[])$$, :'mess', :'rahim'), 'NOT_MANAGER');
select test.check(test.rows(format($$delete from bazar_duties where id = %L$$, :'r1')) = 0, 'outsider delete blocked');

-- Manager edits/swaps and deletes.
select test.act_as(:M);
update bazar_duties set member_id = :'karim' where id = :'r1';
select test.check(test.rows(format($$delete from bazar_duties where id = %L$$, :'k2')) = 1, 'manager deletes');
select test.act_as(null);
