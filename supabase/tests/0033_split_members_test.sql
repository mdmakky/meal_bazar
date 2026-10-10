-- Meal-only members skip automatic equal shares; recurring bills can name who
-- shares them; weights/headcounts stay consistent; members cannot exempt
-- themselves; the fund goes negative when a bill is posted without deposits.
\set M '''33330000-0000-0000-0000-00000000000a'''
\set R '''33330000-0000-0000-0000-00000000000b'''
\set K '''33330000-0000-0000-0000-00000000000c'''
\set L '''33330000-0000-0000-0000-00000000000d'''
insert into auth.users (id) values (:M), (:R), (:K), (:L);
select set_config('meal_bazar.today', '2099-03-05', false);
select test.act_as(:M);
select create_mess('Split Mess', 'Manager') as mess \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :L, 'Lazy') returning id as lazy \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = '2099-01-01' where mess_id = :'mess';
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select id as cat from expense_categories where mess_id = :'mess' limit 1 \gset

-- A member cannot exempt themselves; the manager can.
select test.act_as(:L);
select test.check(test.rows(format($$update mess_members set meal_only = true where id = %L$$, :'lazy')) = 0, 'a member cannot update member rows at all');
select test.act_as(null);
select test.check(not (select meal_only from mess_members where id = :'lazy'), 'flag untouched');
-- The trigger is a second lock: even an update that reaches the row by another route needs a manager.
select test.act_as(:L);
select test.expect_error(format($$insert into mess_members (mess_id, display_name, meal_only) values (%L, 'Ghost', true)$$, :'mess'), 'NOT_MANAGER');
select test.act_as(:M);
update mess_members set meal_only = true where id = :'lazy';
select test.act_as(null);

-- A 1,200 equal bill among 4 members, one of them meal-only → 3 pay 400 each.
insert into expenses (mess_id, date, category_id, amount, split) values (:'mess', '2099-03-02', :'cat', 1200, 'equal');
select test.check((select extra_cost = 400 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim'), 'shared among the 3 who take part');
select test.check((select coalesce(extra_cost, 0) = 0 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'lazy'), 'meal-only member pays no equal share');
select test.check((select sum(extra_cost) = 1200 from member_balances(:'mess', '2099-03-01', '2099-04-01')), 'the whole bill is allocated');
-- Meals still cost them: they are charged by meals as before.
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
select :'mess', :'lazy', id, '2099-03-03', 1 from meal_types where mess_id = :'mess' and name = 'দুপুর';
select test.check((select meals = 1 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'lazy'), 'meals still count');

-- Recurring bill with chosen members (Rahim 2 : Karim 1) → expense_shares copied.
select test.act_as(:M);
insert into recurring_expenses (mess_id, category_id, amount, split, day_of_period) values (:'mess', :'cat', 900, 'equal', 5) returning id as bill \gset
insert into recurring_expense_members (recurring_id, member_id, mess_id, weight)
values (:'bill', :'rahim', :'mess', 2), (:'bill', :'karim', :'mess', 1);
select test.check(apply_recurring_expenses(:'mess', '2099-03-10') = 1, 'posted once');
select test.check(apply_recurring_expenses(:'mess', '2099-03-10') = 0, 'posting again creates nothing');
select test.act_as(null);
select test.check((select count(*) = 2 from expense_shares s join expenses e on e.id = s.expense_id where e.date = '2099-03-05' and e.amount = 900), 'shares copied');
select test.check((select extra_cost = 400 + 600 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim'), 'Rahim: 400 + 2/3 of 900');
select test.check((select extra_cost = 400 + 300 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'karim'), 'Karim: 400 + 1/3 of 900');
select test.check((select coalesce(extra_cost, 0) = 0 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'lazy'), 'not named, not charged');
select test.check((select sum(extra_cost) = 2100 from member_balances(:'mess', '2099-03-01', '2099-04-01')), 'every taka allocated exactly once');
select test.check((select bool_and(opening_balance + credit - food_cost - extra_cost = closing_balance) from member_balances(:'mess', '2099-03-01', '2099-04-01')), 'balance identity');

-- A bill with no named members behaves as before (everyone who takes part).
select test.act_as(:M);
insert into recurring_expenses (mess_id, category_id, amount, split, day_of_period) values (:'mess', :'cat', 300, 'equal', 6);
select apply_recurring_expenses(:'mess', '2099-03-10');
select test.act_as(null);
select test.check((select sum(extra_cost) = 2400 from member_balances(:'mess', '2099-03-01', '2099-04-01')), 'unnamed bill allocated too');

-- With no deposits the mess fund is negative: members' shares are owed, the
-- fund is overdrawn by what was spent from it.
select test.act_as(:M);
select test.check((select cash = -2400 and deposits_in = 0 and fund_spent = 2400 from mess_cash(:'mess', '2099-03-01', '2099-04-01')), 'fund negative without deposits');
select test.check((select count(*) = 3 from member_balances(:'mess', '2099-03-01', '2099-04-01') where closing_balance < 0), 'three members owe their share');

-- A mess that starts mid-month and back-dates a bill: nothing may be lost.
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into auth.users (id) values ('33330000-0000-0000-0000-0000000000e1'), ('33330000-0000-0000-0000-0000000000e2'), ('33330000-0000-0000-0000-0000000000e3');
select test.act_as('33330000-0000-0000-0000-0000000000e1');
select create_mess('Fresh Mess', 'Joy') as fresh \gset
select test.act_as(null);
insert into mess_members (mess_id, user_id, display_name) values (:'fresh', '33330000-0000-0000-0000-0000000000e2', 'Makky') returning id as fm2 \gset
insert into mess_members (mess_id, user_id, display_name) values (:'fresh', '33330000-0000-0000-0000-0000000000e3', 'Widow') returning id as fm3 \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = '2099-03-10' where mess_id = :'fresh';
select id as fcat from expense_categories where mess_id = :'fresh' limit 1 \gset
insert into expenses (mess_id, date, category_id, amount, split) values (:'fresh', '2099-03-04', :'fcat', 900, 'equal');
select test.check((select sum(extra_cost) = 900 from member_balances(:'fresh', '2099-03-01', '2099-04-01')), 'a cost dated before anyone joined is not lost');
select test.check((select bool_and(extra_cost = 300) from member_balances(:'fresh', '2099-03-01', '2099-04-01')), 'shared equally by the first members');
-- A later joiner still does not pay for days before they came.
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name, joined_on) values (:'fresh', null, 'Late', '2099-03-20') returning id as late \gset
select set_config('meal_bazar.trusted', '', false);
insert into expenses (mess_id, date, category_id, amount, split) values (:'fresh', '2099-03-12', :'fcat', 600, 'equal');
select test.check((select coalesce(extra_cost, 0) = 0 from member_balances(:'fresh', '2099-03-01', '2099-04-01') where member_id = :'late'), 'a later joiner does not pay for earlier days');
select test.check((select sum(extra_cost) = 1500 from member_balances(:'fresh', '2099-03-01', '2099-04-01')), 'everything allocated');
select set_config('meal_bazar.today', '', false);
