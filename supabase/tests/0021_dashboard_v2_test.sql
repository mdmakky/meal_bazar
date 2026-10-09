-- Role-aware Home: attention counts, mess cash, transparency, my activity.
\set M '''21210000-0000-0000-0000-00000000000a'''
\set B '''21210000-0000-0000-0000-00000000000b'''
\set C '''21210000-0000-0000-0000-00000000000c'''
\set X '''21210000-0000-0000-0000-00000000000d'''
insert into auth.users (id) values (:M), (:B), (:C), (:X);

select test.act_as(:M);
select create_mess('Home Mess', 'Manager') as mess \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select create_invite(:'mess') as code \gset
select test.act_as(:B);
select join_mess(:'code', 'Bilal') as bilal \gset
select test.act_as(:C);
select join_mess(:'code', 'Chompa') as chompa \gset
select test.act_as(:M);
update mess_members set status = 'active', joined_on = '2026-10-01' where id = :'bilal';
update mess_members set joined_on = '2026-10-01' where id = :'mgr';
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
select id as wifi from expense_categories where mess_id = :'mess' and name = 'ওয়াইফাই' \gset
select id as gas from expense_categories where mess_id = :'mess' and name = 'গ্যাস' \gset

-- ── manager_attention ────────────────────────────────────────────────────
select test.check((select pending_members = 1 and pending_deposits = 0 and meals_missing = 2
                   and pending_recurring = 0
                   from manager_attention(:'mess', '2026-10-10')), 'attention: 1 join request, 2 without meals');
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
values (:'mess', :'mgr', :'lunch', '2026-10-10', 1);
-- An off meal is still "entered".
insert into meal_entries (mess_id, member_id, meal_type_id, date, count, is_off)
values (:'mess', :'bilal', :'lunch', '2026-10-10', 0, true);
select test.check((select meals_missing = 0 from manager_attention(:'mess', '2026-10-10')), 'attention: meals entered');
select test.check((select meals_missing = 0 from manager_attention(:'mess', '2026-09-10')),
                  'attention: nobody present before joining');
insert into recurring_expenses (mess_id, category_id, amount, split, day_of_period)
values (:'mess', :'wifi', 500, 'equal', 1);
select test.check((select pending_recurring = 1 from manager_attention(:'mess', '2026-10-10')), 'attention: recurring');

-- ── mess_cash ────────────────────────────────────────────────────────────
select test.act_as(:B);
select record_my_deposit(:'mess', '21210000-0000-0000-0000-0000000000d1', '2026-10-05', 700, 'bkash', null, null, null);
select test.act_as(:M);
select test.check((select pending_deposits = 1 from manager_attention(:'mess', '2026-10-10')), 'attention: pending deposit');
insert into deposits (mess_id, member_id, date, amount, method) values
  (:'mess', :'bilal', '2026-10-02', 2000, 'cash'),
  (:'mess', :'mgr', '2026-10-03', 1000, 'cash'),
  (:'mess', :'mgr', '2026-11-03', 9999, 'cash');
insert into deposits (mess_id, member_id, date, amount, method, deleted_at)
values (:'mess', :'mgr', '2026-10-03', 5000, 'cash', now());
-- Fund-paid: counts. Own pocket (Bilal): must NOT reduce cash.
insert into bazars (mess_id, date, amount) values (:'mess', '2026-10-04', 800);
insert into bazars (mess_id, date, amount, paid_by_member_id) values (:'mess', '2026-10-06', 300, :'bilal');
insert into expenses (mess_id, date, category_id, amount, split) values (:'mess', '2026-10-07', :'gas', 400, 'meal');
insert into expenses (mess_id, date, category_id, amount, split, paid_by_member_id)
values (:'mess', '2026-10-08', :'wifi', 600, 'equal', :'bilal') returning id as wifi_exp \gset
select test.check((select deposits_in = 3000 and fund_spent = 1200 and cash = 1800 and pending_deposits = 700
                   from mess_cash(:'mess', '2026-10-01', '2026-11-01')), 'cash = verified − fund-paid; pending reported only');
select verify_deposit('21210000-0000-0000-0000-0000000000d1', true);
select test.check((select cash = 2500 and pending_deposits = 0
                   from mess_cash(:'mess', '2026-10-01', '2026-11-01')), 'verified deposit adds to cash');

-- ── member_transparency ──────────────────────────────────────────────────
select test.check((select deposits = 2700 and own_pocket = 900
                   from member_transparency(:'mess', '2026-10-01', '2026-11-01') where member_id = :'bilal'),
                  'transparency: Bilal deposits and own pocket');
select test.check((select bool_and(t.closing_balance = b.closing_balance)
                   from member_transparency(:'mess', '2026-10-01', '2026-11-01') t
                   join member_balances(:'mess', '2026-10-01', '2026-11-01') b using (member_id)),
                  'transparency agrees with member_balances');
select test.check((select count(*) from member_transparency(:'mess', '2026-10-01', '2026-11-01')) = 2,
                  'transparency: pending requester left out');

-- A member reads every member's summary (RLS lets members read the inputs).
select test.act_as(:B);
select test.check((select count(*) from member_transparency(:'mess', '2026-10-01', '2026-11-01')) = 2,
                  'member sees all members');
select test.check((select deposits = 1000 from member_transparency(:'mess', '2026-10-01', '2026-11-01')
                   where member_id = :'mgr'), 'member sees the manager''s deposits');
select test.check((select cash = 2500 from mess_cash(:'mess', '2026-10-01', '2026-11-01')), 'member reads mess cash');

-- ── my_activity ──────────────────────────────────────────────────────────
-- Bilal recorded d1 himself (left out); the manager verified it (in).
select test.check((select count(*) from my_activity(:'mess') where entity = 'deposits'
                   and ref_id = '21210000-0000-0000-0000-0000000000d1') = 1, 'activity: only the verification');
select test.check((select new ->> 'status' = 'verified' and actor_name = 'Manager' and ref_type = 'deposit'
                   from my_activity(:'mess') where ref_id = '21210000-0000-0000-0000-0000000000d1'),
                  'activity: verification by Manager');
select test.check((select count(*) from my_activity(:'mess') where entity = 'deposits') = 2, 'activity: my 2 deposits');
select test.check((select count(*) from my_activity(:'mess') where ref_type = 'bazar') = 1, 'activity: own-pocket bazar');
select test.check((select count(*) from my_activity(:'mess') where ref_id = :'wifi_exp') = 1, 'activity: expense I paid');
-- The off-meal insert concerns me; the manager's own meal does not.
select test.check((select count(*) from my_activity(:'mess') where ref_type = 'meal') = 1, 'activity: my off meal');

select test.act_as(:M);
-- A plain filled meal (count 1, no guest, not off) is noise: left out.
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
values (:'mess', :'bilal', :'lunch', '2026-10-11', 1);
-- A change to it is in.
update meal_entries set count = 0.5 where member_id = :'bilal' and date = '2026-10-11';
-- An expense shared with Bilal, and a bazar he went to.
insert into expenses (mess_id, date, category_id, amount, split) values (:'mess', '2026-10-09', :'wifi', 100, 'equal')
returning id as shared_exp \gset
select set_expense_shares(:'shared_exp', jsonb_build_array(jsonb_build_object('member_id', :'bilal')));
insert into bazars (mess_id, date, amount) values (:'mess', '2026-10-12', 250) returning id as went \gset
select set_bazar_buyers(:'went', array[:'bilal']::uuid[]);
-- Not about Bilal: fund bazar nobody went to, manager's own deposit.
insert into bazars (mess_id, date, amount) values (:'mess', '2026-10-13', 90);

select test.act_as(:B);
select test.check((select count(*) from my_activity(:'mess') where ref_type = 'meal') = 2, 'activity: meal change in, plain fill out');
select test.check((select action = 'update' and (old ->> 'count')::numeric = 1 and (new ->> 'count')::numeric = 0.5
                   from my_activity(:'mess') where ref_type = 'meal' limit 1), 'activity: newest meal change first');
select test.check((select array_agg(at order by n) = array_agg(at order by at desc, id desc)
                   from my_activity(:'mess') with ordinality t(id, at, action, entity, ref_type, ref_id, actor_id,
                                                              actor_name, old, new, n)), 'activity: newest first');
select test.check((select count(*) from my_activity(:'mess') where ref_id = :'shared_exp') = 1, 'activity: shared expense');
select test.check((select count(*) from my_activity(:'mess') where ref_id = :'went') >= 1, 'activity: bazar I went to');
select test.check((select count(*) from my_activity(:'mess') where ref_type = 'bazar') >= 2
                   and not exists (select 1 from my_activity(:'mess') where (new ->> 'amount')::numeric = 90),
                  'activity: unrelated bazar left out');
select test.check((select count(*) from my_activity(:'mess', 2)) = 2, 'activity: limit');
select test.check((select count(*) from my_activity(:'mess', 100000)) <= 100, 'activity: limit capped');

-- The manager's view of my_activity is about the manager (nothing by others).
select test.act_as(:M);
select test.check((select count(*) from my_activity(:'mess')) = 0, 'manager: own actions left out');

-- Pending requester and outsider: nothing.
select test.act_as(:C);
select test.check((select count(*) from my_activity(:'mess')) = 0, 'pending: no activity');
select test.check((select count(*) from manager_attention(:'mess', '2026-10-10')) = 0, 'pending: no attention');
select test.act_as(:X);
select test.check((select count(*) from my_activity(:'mess')) = 0, 'outsider: no activity');
select test.check((select count(*) from manager_attention(:'mess', '2026-10-10')) = 0, 'outsider: no attention');
select test.check((select count(*) from mess_cash(:'mess', '2026-10-01', '2026-11-01')) = 0, 'outsider: no cash');
select test.check((select count(*) from member_transparency(:'mess', '2026-10-01', '2026-11-01')) = 0, 'outsider: no transparency');
select test.act_as(null);
