-- Withdrawals: manager only, up to the member's balance, net everywhere
-- (balance, fund, totals), idempotent, closed months and future dates refused.
\set M '''36360000-0000-0000-0000-00000000000a'''
\set R '''36360000-0000-0000-0000-00000000000b'''
\set K '''36360000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:K);
select set_config('meal_bazar.today', '2099-03-20', false);
select test.act_as(:M);
select create_mess('Withdraw Mess', 'Joy') as mess \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = '2099-01-01' where mess_id = :'mess';
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
insert into device_tokens (token, user_id, platform) values ('tok-withdraw-rahim', :R, 'android');
-- Rahim deposits 2,000; Karim deposits 500 and has a 100 meal cost.
insert into deposits (mess_id, member_id, date, amount, method) values (:'mess', :'rahim', '2099-03-02', 2000, 'cash'), (:'mess', :'karim', '2099-03-02', 500, 'cash');
select test.check((select closing_balance = 2000 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim'), 'Rahim is owed 2,000');

-- Members cannot record one; the table itself refuses a member's insert.
select test.act_as(:R);
select test.expect_error(format($$select record_withdrawal(%L, gen_random_uuid(), %L, '2099-03-10', 100, 'cash', null)$$, :'mess', :'rahim'), 'NOT_MANAGER');
select test.expect_error(format($$insert into deposits (mess_id, member_id, date, amount, kind, method, status) values (%L, %L, '2099-03-10', -100, 'withdrawal', 'cash', 'verified')$$, :'mess', :'rahim'), 'row-level security');
select test.act_as(:M);
-- More than the balance is refused; sign and kind must agree.
select test.expect_error(format($$select record_withdrawal(%L, gen_random_uuid(), %L, '2099-03-10', 2000.01, 'cash', null)$$, :'mess', :'rahim'), 'WITHDRAWAL_EXCEEDS_BALANCE');
select test.expect_error(format($$select record_withdrawal(%L, gen_random_uuid(), %L, '2099-03-10', 0, 'cash', null)$$, :'mess', :'rahim'), 'AMOUNT_INVALID');
select test.expect_error(format($$select record_withdrawal(%L, gen_random_uuid(), %L, '2099-03-25', 10, 'cash', null)$$, :'mess', :'rahim'), 'FUTURE_DATE');
select test.expect_error(format($$insert into deposits (mess_id, member_id, date, amount, kind, method) values (%L, %L, '2099-03-10', 100, 'withdrawal', 'cash')$$, :'mess', :'rahim'), 'deposits_amount_sign');
select test.expect_error(format($$insert into deposits (mess_id, member_id, date, amount, kind, method) values (%L, %L, '2099-03-10', -100, 'deposit', 'cash')$$, :'mess', :'rahim'), 'deposits_amount_sign');
-- Karim owes more than he deposited: nothing to take out.
insert into meal_entries (mess_id, member_id, meal_type_id, date, count) select :'mess', :'karim', id, '2099-03-03', 5 from meal_types where mess_id = :'mess' and name = 'দুপুর';
insert into bazars (mess_id, date, amount) values (:'mess', '2099-03-04', 2000);
select test.check((select closing_balance < 500 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'karim'), 'Karim spent part of his deposit');

-- Pay Rahim back 800: his credit and the fund both fall by exactly 800.
select closing_balance as r_before from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim' \gset
select cash as cash_before from mess_cash(:'mess', '2099-03-01', '2099-04-01') \gset
select record_withdrawal(:'mess', '36360000-0000-0000-0000-0000000000a1', :'rahim', '2099-03-10', 800, 'cash', ' for rent ') as w \gset
select record_withdrawal(:'mess', '36360000-0000-0000-0000-0000000000a1', :'rahim', '2099-03-10', 800, 'cash', ' for rent ');   -- retry
select test.check((select count(*) = 1 and bool_and(amount = -800 and kind = 'withdrawal' and status = 'verified' and note = 'for rent') from deposits where id = '36360000-0000-0000-0000-0000000000a1'), 'one verified withdrawal, retry harmless');
select test.check((select closing_balance = :r_before - 800 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim'), 'member balance down 800');
select test.check((select cash = :cash_before - 800 from mess_cash(:'mess', '2099-03-01', '2099-04-01')), 'fund down 800');
select test.check((select credit_total = 2500 - 800 from month_totals(:'mess', '2099-03-01', '2099-04-01')), 'month deposits are net');
-- Not more than what is left: 1,200 remains, 1,201 is refused.
select test.expect_error(format($$select record_withdrawal(%L, gen_random_uuid(), %L, '2099-03-11', 1200.01, 'cash', null)$$, :'mess', :'rahim'), 'WITHDRAWAL_EXCEEDS_BALANCE');
select record_withdrawal(:'mess', gen_random_uuid(), :'rahim', '2099-03-11', 1200, 'bkash', null);
select test.check((select closing_balance = 0 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim'), 'fully paid back');
select test.check((select bool_and(opening_balance + credit - food_cost - extra_cost = closing_balance) from member_balances(:'mess', '2099-03-01', '2099-04-01')), 'identity holds');
-- The member is told, in the right words.
select test.act_as(null);
select test.check((select count(*) = 2 from notifications where user_id = :R and type = 'deposit_added' and title = 'টাকা ফেরত'), 'member told about each payback');
select test.check((select body = 'আপনাকে ৳৮০০ ফেরত দেওয়া হয়েছে' from notifications where user_id = :R and title = 'টাকা ফেরত' order by id limit 1), 'amount shown positive');
-- Closed month: nothing can be recorded in it.
insert into months (mess_id, start_date, end_date, status, closed_at, food_total) values (:'mess', '2099-02-01', '2099-03-01', 'closed', now(), 0);
select test.act_as(:M);
select test.expect_error(format($$select record_withdrawal(%L, gen_random_uuid(), %L, '2099-02-15', 1, 'cash', null)$$, :'mess', :'rahim'), 'MONTH_CLOSED');
select set_config('meal_bazar.today', '', false);
