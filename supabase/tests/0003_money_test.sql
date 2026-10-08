-- Money: categories seeded, constraints, same-mess FKs, item mess, RLS.
\set M '''22222222-0000-0000-0000-00000000000a'''
\set X '''22222222-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:X);

select test.act_as(:M);
select create_mess('Money Mess', 'Manager') as mess \gset
select test.check((select count(*) from expense_categories where mess_id = :'mess') = 9, 'expense categories seeded');
select id as wifi from expense_categories where mess_id = :'mess' and name = 'ওয়াইফাই' \gset
insert into mess_members (mess_id, display_name) values (:'mess', 'Rahim') returning id as rahim \gset

-- Constraints.
select test.expect_error(format($$insert into bazars (mess_id, date, amount) values (%L, '2026-10-02', -5)$$, :'mess'), 'check');
select test.expect_error(format($$insert into deposits (mess_id, member_id, date, amount) values (%L, %L, '2026-10-02', 0)$$, :'mess', :'rahim'), 'check');
-- numeric(12,2) rounds extra decimals rather than rejecting them.
insert into expenses (mess_id, date, category_id, amount, split) values (:'mess', '2026-10-02', :'wifi', 1.235, 'equal') returning amount as rounded \gset
select test.check(:'rounded'::numeric = 1.24, 'money stored at 2 decimals');

-- Bazar with items; item mess comes from the bazar.
insert into bazars (mess_id, date, buyer_member_id, amount, paid_by_member_id)
values (:'mess', '2026-10-02', :'rahim', 120, :'rahim') returning id as bazar \gset
insert into bazar_items (bazar_id, mess_id, name, qty, unit, price) values (:'bazar', :'mess', 'আলু', 2, 'kg', 120);
select test.check((select mess_id from bazar_items where bazar_id = :'bazar') = :'mess', 'item mess set');

-- Cross-mess references are impossible.
select create_mess('Other Mess', 'Manager') as other \gset
select test.expect_error(format($$insert into deposits (mess_id, member_id, date, amount) values (%L, %L, '2026-10-02', 100)$$, :'other', :'rahim'), 'foreign key');
select test.expect_error(format($$insert into expenses (mess_id, date, category_id, amount, split) values (%L, '2026-10-02', %L, 10, 'equal')$$, :'other', :'wifi'), 'foreign key');

-- RLS.
select test.act_as(:X);
select test.check((select count(*) from bazars) + (select count(*) from bazar_items) + (select count(*) from expenses)
                  + (select count(*) from deposits) + (select count(*) from expense_categories) = 0, 'outsider sees no money rows');
select test.expect_error(format($$insert into bazars (mess_id, date, amount) values (%L, '2026-10-02', 5)$$, :'mess'), 'row-level security');
select test.act_as(null);
select test.check((select count(*) from audit_log where entity = 'bazars') = 1, 'bazar audited');
