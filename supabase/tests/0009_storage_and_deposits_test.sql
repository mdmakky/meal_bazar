select set_config('meal_bazar.today', '2099-12-31', false);   -- months close only after they end (0032)
-- Member-recorded deposits (pending → verified/rejected) and receipts storage policies.
\set M '''99999999-0000-0000-0000-00000000000a'''
\set B '''99999999-0000-0000-0000-00000000000b'''
\set X '''99999999-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:B), (:X);

select test.act_as(:M);
select create_mess('Deposit Mess', 'Manager') as mess \gset
select create_invite(:'mess') as code \gset
select test.act_as(:B);
select join_mess(:'code', 'Bilal') as bilal \gset
select test.act_as(:M);
update mess_members set status = 'active', joined_on = '2026-10-01' where id = :'bilal';
update mess_members set joined_on = '2026-10-01' where mess_id = :'mess' and user_id = :M;

-- Member records a pending deposit: not counted until verified.
select test.act_as(:B);
select record_my_deposit(:'mess', '99999999-0000-0000-0000-0000000000d1', '2026-10-05', 500, 'bkash',
                         ' BK1 ', '', :'mess' || '/99999999-0000-0000-0000-0000000000f1.jpg');
select test.check((select status = 'pending' and member_id = :'bilal' and trx_id = 'BK1' and note is null
                   and screenshot_path like :'mess' || '/%'
                   from deposits where id = '99999999-0000-0000-0000-0000000000d1'), 'pending row for own member');
select test.check((select credit = 0 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'bilal'),
                  'pending deposit not credited');
-- Idempotent retry; a foreign id is refused.
select record_my_deposit(:'mess', '99999999-0000-0000-0000-0000000000d1', '2026-10-05', 500, 'bkash', 'BK1', null, null);
select test.check((select count(*) from deposits where mess_id = :'mess') = 1, 'retry is idempotent');
select test.expect_error(format($$select record_my_deposit(%L, gen_random_uuid(), '2026-10-05', 10, 'cash', null, null, 'other/x.jpg')$$, :'mess'), 'RECEIPT_PATH_INVALID');
select test.expect_error(format($$select record_my_deposit(%L, gen_random_uuid(), '2026-10-05', 0, 'cash', null, null, null)$$, :'mess'), 'check');
-- Member cannot verify (own or any) deposit, nor write deposits directly.
select test.expect_error($$select verify_deposit('99999999-0000-0000-0000-0000000000d1', true)$$, 'NOT_MANAGER');
select test.check(test.rows($$update deposits set status = 'verified'$$) = 0, 'member cannot set status directly');

-- Outsider: cannot record or verify.
select test.act_as(:X);
select test.expect_error(format($$select record_my_deposit(%L, gen_random_uuid(), '2026-10-05', 10, 'cash', null, null, null)$$, :'mess'), 'NOT_MEMBER');
select test.expect_error($$select verify_deposit('99999999-0000-0000-0000-0000000000d1', true)$$, 'NOT_MANAGER');

-- Manager verifies → counted; audited.
select test.act_as(:M);
select verify_deposit('99999999-0000-0000-0000-0000000000d1', true);
select test.check((select credit = 500 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'bilal'),
                  'verified deposit credited');
select test.expect_error($$select verify_deposit('99999999-0000-0000-0000-0000000000d1', false)$$, 'DEPOSIT_NOT_PENDING');
select test.check(exists (select 1 from audit_log where entity = 'deposits' and action = 'update'
                          and entity_id = '99999999-0000-0000-0000-0000000000d1'
                          and old ->> 'status' = 'pending' and new ->> 'status' = 'verified'), 'verification audited');

-- Reject → not counted.
select test.act_as(:B);
select record_my_deposit(:'mess', '99999999-0000-0000-0000-0000000000d2', '2026-10-06', 300, 'cash', null, null, null);
select test.act_as(:M);
select verify_deposit('99999999-0000-0000-0000-0000000000d2', false);
select test.check((select status = 'rejected' from deposits where id = '99999999-0000-0000-0000-0000000000d2'), 'rejected');
select test.check((select credit = 500 from member_balances(:'mess', '2026-10-01', '2026-11-01') where member_id = :'bilal'),
                  'rejected deposit not credited');

-- Closed month guard applies to both RPCs.
select test.act_as(:B);
select record_my_deposit(:'mess', '99999999-0000-0000-0000-0000000000d3', '2026-10-07', 200, 'nagad', null, null, null);
select test.act_as(:M);
-- A pending deposit blocks the close (0026), so it can never be stranded.
select test.expect_error(format($$select close_month(%L, '2026-10-01', true)$$, :'mess'), 'PENDING_ITEMS');
select verify_deposit('99999999-0000-0000-0000-0000000000d3', true);
select close_month(:'mess', '2026-10-01', true);
select test.act_as(:B);
select test.expect_error(format($$select record_my_deposit(%L, gen_random_uuid(), '2026-10-20', 10, 'cash', null, null, null)$$, :'mess'), 'MONTH_CLOSED');
select test.act_as(null);

-- receipt_mess: only a uuid first segment counts.
select test.check(receipt_mess(:'mess' || '/a.jpg') = :'mess'::uuid, 'receipt_mess parses');
select test.check(receipt_mess('nope/a.jpg') is null and receipt_mess('a.jpg') is null, 'receipt_mess rejects junk');

-- Storage policies: replay the migration against a minimal storage stub (Supabase has the real one).
create schema storage;
create table storage.buckets (id text primary key, name text not null, public boolean not null default false);
create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text);
alter table storage.objects enable row level security;
grant usage on schema storage to authenticated;
grant all on storage.objects to authenticated;
set client_min_messages = warning;
\ir ../migrations/0009_storage_and_deposits.sql
select test.check((select not public from storage.buckets where id = 'receipts'), 'private receipts bucket');

select test.act_as(:M);
insert into storage.objects (bucket_id, name) values ('receipts', :'mess' || '/m.jpg');
select test.act_as(:B);
insert into storage.objects (bucket_id, name) values ('receipts', :'mess' || '/b.jpg');
select test.check((select count(*) from storage.objects) = 2, 'member reads mess receipts');
select test.check(test.rows($$delete from storage.objects$$) = 0, 'member cannot delete');
select test.check(test.rows($$update storage.objects set name = name$$) = 0, 'member cannot update');
select test.act_as(:X);
select test.check((select count(*) from storage.objects) = 0, 'outsider reads nothing');
select test.expect_error(format($$insert into storage.objects (bucket_id, name) values ('receipts', %L)$$, :'mess' || '/x.jpg'), 'row-level security');
select test.expect_error($$insert into storage.objects (bucket_id, name) values ('receipts', 'junk/x.jpg')$$, 'row-level security');
select test.act_as(:M);
select test.check(test.rows($$delete from storage.objects where name like '%/b.jpg'$$) = 1, 'manager deletes');
select test.act_as(null);
