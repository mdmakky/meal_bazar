select set_config('meal_bazar.today', '2099-12-31', false);   -- months close only after they end (0032)
-- Bazar buyers: RPC replaces the set, first buyer mirrored, RLS, closed month, backfill.
\set M '''18181818-0000-0000-0000-00000000000a'''
\set U '''18181818-0000-0000-0000-00000000000b'''
\set X '''18181818-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:U), (:X);

select test.act_as(:M);
select create_mess('Buyer Mess', 'Manager') as mess \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
insert into mess_members (mess_id, display_name) values (:'mess', 'A') returning id as a \gset
insert into mess_members (mess_id, display_name) values (:'mess', 'B') returning id as b \gset
select create_invite(:'mess') as code \gset
select test.act_as(:U);
select join_mess(:'code', 'U') as u \gset
select test.act_as(:M);
update mess_members set status = 'active' where id = :'u';

insert into bazars (mess_id, date, buyer_member_id, amount, paid_by_member_id)
values (:'mess', '2026-10-02', :'a', 500, :'b') returning id as bz \gset

-- Two buyers; the first is mirrored into buyer_member_id; money is untouched.
select set_bazar_buyers(:'bz', array[:'b', :'a']::uuid[]);
select test.check((select count(*) from bazar_buyers where bazar_id = :'bz') = 2, 'two buyers');
select test.check((select mess_id from bazar_buyers where member_id = :'a') = :'mess', 'buyer mess set from bazar');
select test.check((select buyer_member_id from bazars where id = :'bz') = :'b', 'first buyer mirrored');
select test.check((select paid_by_member_id from bazars where id = :'bz') = :'b'
              and (select amount from bazars where id = :'bz') = 500, 'payer and amount untouched');

-- Replace the whole set.
select set_bazar_buyers(:'bz', array[:'mgr']::uuid[]);
select test.check((select array_agg(member_id) from bazar_buyers where bazar_id = :'bz') = array[:'mgr']::uuid[], 'set replaced');
select test.check((select buyer_member_id from bazars where id = :'bz') = :'mgr', 'mirror follows');
select test.check((select count(*) from audit_log where entity = 'bazar_buyers') = 0, 'buyers not audited (0030)');

-- Members of another mess are refused.
select create_mess('Other Buyer Mess', 'Manager') as other \gset
select id as othermgr from mess_members where mess_id = :'other' \gset
select test.expect_error(format($$select set_bazar_buyers(%L, array[%L]::uuid[])$$, :'bz', :'othermgr'), 'NOT_MEMBER');
select test.expect_error(format($$select set_bazar_buyers(%L, array[%L]::uuid[])$$, gen_random_uuid(), :'a'), 'NOT_FOUND');

-- A plain member reads but cannot write.
select test.act_as(:U);
select test.check((select count(*) from bazar_buyers) = 1, 'member reads buyers');
select test.expect_error(format($$select set_bazar_buyers(%L, array[%L]::uuid[])$$, :'bz', :'a'), 'NOT_MANAGER');
select test.expect_error(format($$insert into bazar_buyers (bazar_id, mess_id, member_id) values (%L, %L, %L)$$, :'bz', :'mess', :'a'), 'row-level security');
select test.check(test.rows(format($$delete from bazar_buyers where bazar_id = %L$$, :'bz')) = 0, 'member delete does nothing');

-- An outsider sees nothing.
select test.act_as(:X);
select test.check((select count(*) from bazar_buyers) = 0, 'outsider sees no buyers');
select test.expect_error(format($$select set_bazar_buyers(%L, array[%L]::uuid[])$$, :'bz', :'a'), 'NOT_FOUND');

-- Closed month: buyers are frozen with their bazar.
select test.act_as(:M);
update mess_members set joined_on = '2026-10-01' where mess_id = :'mess';
select close_month(:'mess', '2026-10-02', true) as oct \gset
select test.expect_error(format($$select set_bazar_buyers(%L, array[%L]::uuid[])$$, :'bz', :'a'), 'MONTH_CLOSED');
select test.expect_error(format($$delete from bazar_buyers where bazar_id = %L$$, :'bz'), 'MONTH_CLOSED');

-- Backfill (same statement as 0018): one row per bazar from buyer_member_id.
select test.act_as(null);
insert into bazars (mess_id, date, buyer_member_id, amount) values (:'mess', '2026-11-03', :'a', 50) returning id as old \gset
insert into bazar_buyers (bazar_id, member_id)
select id, buyer_member_id from bazars b where buyer_member_id is not null
  and not exists (select 1 from bazar_buyers x where x.bazar_id = b.id);
select test.check((select array_agg(member_id) from bazar_buyers where bazar_id = :'old') = array[:'a']::uuid[], 'backfill one row from buyer');
