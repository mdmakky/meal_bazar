-- Expense shares: split among selected members by weight, fallback, RLS, closed month.
\set M '''12121212-0000-0000-0000-00000000000a'''
\set X '''12121212-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:X);

select test.act_as(:M);
select create_mess('Share Mess', 'Manager') as mess \gset
update mess_members set joined_on = '2026-10-01' where mess_id = :'mess';
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select id as rent from expense_categories where mess_id = :'mess' and name = 'বাসা ভাড়া' \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'A', '2026-10-01') returning id as a \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'B', '2026-10-01') returning id as b \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'C', '2026-10-01') returning id as c \gset
insert into mess_members (mess_id, display_name, joined_on) values (:'mess', 'D', '2026-10-01') returning id as d \gset

create temp view ex as select member_id, extra_cost from member_balances(
  (select id from messes where name = 'Share Mess'), '2026-10-01', '2026-11-01');
grant select on ex to authenticated;

-- 3 of 5 members share ৳900 → ৳300 each, others 0.
insert into expenses (mess_id, date, category_id, amount, split) values (:'mess', '2026-10-05', :'rent', 900, 'equal') returning id as e \gset
select set_expense_shares(:'e', jsonb_build_array(
  jsonb_build_object('member_id', :'a'), jsonb_build_object('member_id', :'b'), jsonb_build_object('member_id', :'c')));
select test.check((select mess_id from expense_shares where member_id = :'a') = :'mess', 'share mess set from expense');
select test.check((select extra_cost from ex where member_id = :'a') = 300
              and (select extra_cost from ex where member_id = :'b') = 300
              and (select extra_cost from ex where member_id = :'c') = 300
              and (select extra_cost from ex where member_id = :'d') = 0
              and (select extra_cost from ex where member_id = :'mgr') = 0, '900 among 3 selected → 300 each');

-- Weights 2:1 → 600/300.
select set_expense_shares(:'e', jsonb_build_array(
  jsonb_build_object('member_id', :'a', 'weight', 2), jsonb_build_object('member_id', :'b', 'weight', 1)));
select test.check((select extra_cost from ex where member_id = :'a') = 600
              and (select extra_cost from ex where member_id = :'b') = 300
              and (select extra_cost from ex where member_id = :'c') = 0, 'weights 2:1 → 600/300');
select test.expect_error(format($$insert into expense_shares (expense_id, mess_id, member_id, weight) values (%L, %L, %L, 0)$$, :'e', :'mess', :'c'), 'check');

-- No shares → old equal split among the 5 present members.
select set_expense_shares(:'e', '[]');
select test.check((select count(*) from ex where extra_cost = 180) = 5, 'no shares → equal among present');

-- Cross-mess member is impossible.
select create_mess('Other Share Mess', 'Manager') as other \gset
select id as othermgr from mess_members where mess_id = :'other' \gset
select test.expect_error(format($$select set_expense_shares(%L, jsonb_build_array(jsonb_build_object('member_id', %L)))$$, :'e', :'othermgr'), 'foreign key');

-- Outsider sees nothing and cannot write.
select set_expense_shares(:'e', jsonb_build_array(jsonb_build_object('member_id', :'a')));
select test.act_as(:X);
select test.check((select count(*) from expense_shares) = 0, 'outsider sees no shares');
select test.expect_error(format($$select set_expense_shares(%L, '[{"member_id": "%s"}]')$$, :'e', :'b'), 'row-level security');
select test.act_as(:M);
select test.check((select count(*) from expense_shares where expense_id = :'e') = 1, 'outsider delete did nothing');

-- Closed month: shares are frozen with their expense; snapshot used them.
select close_month(:'mess', '2026-10-05') as oct \gset
select test.check((select extra_cost from month_member_summary where month_id = :'oct' and member_id = :'a') = 900, 'snapshot uses shares');
select test.expect_error(format($$select set_expense_shares(%L, '[]')$$, :'e'), 'MONTH_CLOSED');
select test.expect_error(format($$update expense_shares set weight = 3 where expense_id = %L$$, :'e'), 'MONTH_CLOSED');
select test.act_as(null);
