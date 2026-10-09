-- Month lifecycle: close only after the month ended, pending items, missing
-- meals confirmed + audited, auto-meal status gate, frozen snapshots,
-- carry-forward exactly once (also while a month is reopened), reopen audit.
\set M '''32320000-0000-0000-0000-00000000000a'''
\set R '''32320000-0000-0000-0000-00000000000b'''
\set K '''32320000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:K);
select set_config('meal_bazar.today', '2099-02-15', false);
select test.act_as(:M);
select create_mess('Lifecycle Mess', 'Manager') as mess \gset
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = '2098-12-01' where mess_id = :'mess';
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
-- February: everyone has an entry every day except Karim on the 5th and 6th.
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
select :'mess', m, :'lunch', d::date, 1
from generate_series('2099-02-01'::date, '2099-02-28', interval '1 day') d,
     unnest(array[:'mgr'::uuid, :'rahim'::uuid, :'karim'::uuid]) m
where not (m = :'karim'::uuid and d::date in ('2099-02-05', '2099-02-06'));
insert into bazars (mess_id, date, amount) values (:'mess', '2099-02-03', 840);
insert into deposits (mess_id, member_id, date, amount, method) values (:'mess', :'rahim', '2099-02-02', 1000, 'cash');
select id as cat from expense_categories where mess_id = :'mess' limit 1 \gset
insert into expenses (mess_id, date, category_id, amount, split, paid_by_member_id)
values (:'mess', '2099-02-10', :'cat', 90, 'equal', :'karim');

select test.act_as(:M);
-- A month that has not ended cannot be closed.
select test.expect_error(format($$select close_month(%L, '2099-02-10', true)$$, :'mess'), 'MONTH_NOT_ENDED');
select set_config('meal_bazar.today', '2099-03-05', false);
-- Missing member-days: exactly Karim on the 5th and 6th (one definition).
select test.check((select count(*) = 2 and bool_and(member_id = :'karim')
                   from month_missing_meals(:'mess', '2099-02-01', '2099-03-01')), 'missing meals');
select test.check((select missing_days = 2 and status = 'open' and not can_close is null
                   from month_review(:'mess') where start_date = '2099-02-01'), 'status: open, 2 missing');
select test.expect_error(format($$select close_month(%L, '2099-02-10')$$, :'mess'), 'MISSING_MEALS');
select test.check((select count(*) = 0 from months where mess_id = :'mess')
                  and (select count(*) = 0 from month_member_summary where mess_id = :'mess'), 'a refused close leaves nothing behind');
-- A pending deposit blocks the close, and cannot be confirmed away.
select test.act_as(null);
insert into deposits (mess_id, member_id, date, amount, method, status) values (:'mess', :'karim', '2099-02-20', 5, 'cash', 'pending') returning id as pdep \gset
select test.act_as(:M);
select test.expect_error(format($$select close_month(%L, '2099-02-10', true)$$, :'mess'), 'PENDING_ITEMS');
select test.check((select pending_deposits = 1 and not can_close from month_review(:'mess')), 'status: pending deposit blocks');
select verify_deposit(:'pdep', false);

-- Auto-meal gate: the last day must be 'ok' (not just have a record).
select test.act_as(null);
update messes set auto_meals = true where id = :'mess';
update messes set auto_meals_since = '2099-01-01' where id = :'mess';
select test.act_as(:M);
select test.check((select auto_state = 'pending' and not can_close from month_review(:'mess')), 'auto: pending');
select test.expect_error(format($$select close_month(%L, '2099-02-10', true)$$, :'mess'), 'AUTO_MEALS_PENDING');
select test.act_as(null);
insert into auto_meal_runs (mess_id, date, status, error) values (:'mess', '2099-02-28', 'failed', '23000');
select test.act_as(:M);
select test.expect_error(format($$select close_month(%L, '2099-02-10', true)$$, :'mess'), 'AUTO_MEALS_PENDING');
select test.check((select auto_state = 'failed' from month_review(:'mess')), 'auto: failed');
select test.act_as(null);
update auto_meal_runs set status = 'incomplete' where mess_id = :'mess';
select test.act_as(:M);
select test.expect_error(format($$select close_month(%L, '2099-02-10', true)$$, :'mess'), 'AUTO_MEALS_PENDING');
select test.act_as(null);
update auto_meal_runs set status = 'ok' where mess_id = :'mess';
select test.act_as(:M);

-- Record the live figures, then close with the missing days confirmed.
select closing_balance as rahim_feb_live from member_balances(:'mess', '2099-02-01', '2099-03-01') where member_id = :'rahim' \gset
select closing_balance as karim_feb_live from member_balances(:'mess', '2099-02-01', '2099-03-01') where member_id = :'karim' \gset
select meal_rate as rate_live from month_totals(:'mess', '2099-02-01', '2099-03-01') \gset
select close_month(:'mess', '2099-02-10', true) as feb \gset
select test.check((select closed_missing = 2 and not totals_reconstructed and food_total = 840 and closed_at is not null
                   from months where id = :'feb'), 'closed: totals stored, missing confirmed');
select test.check((select (new ->> 'missing_meal_days_confirmed')::int = 2 from audit_log
                   where entity_id = :'feb' and action = 'close_month'), 'confirmation audited');
select test.check((select closing_balance = :rahim_feb_live from member_balances(:'mess', '2099-02-01', '2099-03-01') where member_id = :'rahim'), 'snapshot = live at close (Rahim)');
select test.check((select status = 'closed' and closed_missing = 2 from month_review(:'mess') where start_date = '2099-02-01'), 'status: closed');
-- Retry: refused, nothing rewritten.
select closed_at as t0 from months where id = :'feb' \gset
select test.expect_error(format($$select close_month(%L, '2099-02-10', true)$$, :'mess'), 'MONTH_CLOSED');
select test.check((select closed_at = :'t0' from months where id = :'feb')
                  and (select count(*) = 3 from month_member_summary where month_id = :'feb')
                  and (select count(*) = 1 from months where mess_id = :'mess'), 'retry changes nothing');

-- History is frozen: meal weight, rate mode and member dates cannot move it.
update meal_types set weight = 3 where id = :'lunch';
select test.act_as(null);
update messes set meal_rate_mode = 'fixed', fixed_meal_rate = 77 where id = :'mess';
update mess_members set joined_on = '2099-02-25' where id = :'karim';
select test.check((select closing_balance = :karim_feb_live from member_balances(:'mess', '2099-02-01', '2099-03-01') where member_id = :'karim'), 'frozen: Karim');
select test.check((select meal_rate = :rate_live from month_totals(:'mess', '2099-02-01', '2099-03-01')), 'frozen: meal rate');
update messes set meal_rate_mode = 'calculated', fixed_meal_rate = null where id = :'mess';
update mess_members set joined_on = '2098-12-01' where id = :'karim';
update meal_types set weight = 1 where id = :'lunch';

-- Carry-forward: March opens with February's closing, once.
select test.check((select bool_and(o.opening_balance = f.closing_balance)
                   from member_balances(:'mess', '2099-03-01', '2099-04-01') o
                   join member_balances(:'mess', '2099-02-01', '2099-03-01') f using (member_id)), 'March opening = February closing');
select test.expect_error(format($$insert into months (mess_id, start_date, end_date, status, closed_at, food_total)
  values (%L, '2099-02-15', '2099-03-01', 'closed', now(), 0)$$, :'mess'), 'unique');
insert into deposits (mess_id, member_id, date, amount, method) values (:'mess', :'karim', '2099-03-02', 200, 'cash');
select test.check((select bool_and(opening_balance + credit - food_cost - extra_cost = closing_balance)
                   from member_balances(:'mess', '2099-03-01', '2099-04-01')), 'balance identity in March');
select test.check((select credit = 200 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'karim'), 'March deposit counted in March only');

-- Reopen: reason, audit, notification, "correcting", provisional carry-forward.
select test.act_as(null);
insert into device_tokens (token, user_id, platform) values ('tok-lifecycle-rahim', :R, 'android');
select test.act_as(:M);
select test.expect_error(format($$select reopen_month(%L, 'no')$$, :'feb'), 'REASON_REQUIRED');
select closing_balance as rahim_mar_before from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim' \gset
select reopen_month(:'feb', 'Rahim deposit was missed');
select test.check((select status = 'open' and reopen_reason = 'Rahim deposit was missed' and reopened_at is not null
                   from months where id = :'feb'), 'reopened with reason');
select test.check((select status = 'correcting' from month_review(:'mess') where start_date = '2099-02-01'), 'status: correcting');
select test.check(exists (select 1 from audit_log where action = 'reopen_month' and reason = 'Rahim deposit was missed'), 'reopen audited');
select test.act_as(null);
select test.check((select count(*) = 1 from push_outbox where user_id = :R and type = 'month_reopened'), 'members notified of reopen');
select test.act_as(:M);
-- No silent zero: March keeps the (provisional) carry-forward, identical until edited.
select test.check(opening_is_provisional(:'mess', '2099-03-01'), 'opening is provisional while reopened');
select test.check((select closing_balance = :rahim_mar_before from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim'), 'no change before any correction');
-- A correction of exactly 50 moves March's figures by exactly 50 (no double count).
insert into deposits (mess_id, member_id, date, amount, method) values (:'mess', :'rahim', '2099-02-20', 50, 'cash');
select test.check((select closing_balance = :rahim_mar_before + 50 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim'), 'correction carries exactly once');
select test.check((select bool_and(opening_balance + credit - food_cost - extra_cost = closing_balance)
                   from member_balances(:'mess', '2099-03-01', '2099-04-01')), 'identity holds while correcting');
select close_month(:'mess', '2099-02-10', true);
select test.check((select reopened_at is null and reopen_reason is null and status = 'closed' from months where id = :'feb'), 'closing again clears the correction');
select test.check((select opening_balance = :rahim_mar_before + 50 from member_balances(:'mess', '2099-03-01', '2099-04-01') where member_id = :'rahim'), 'frozen again, +50 exactly once');
select test.check(not opening_is_provisional(:'mess', '2099-03-01'), 'no longer provisional');
select test.check((select count(*) = 3 from month_member_summary where month_id = :'feb') and (select count(*) = 1 from months where mess_id = :'mess' and status = 'closed'), 'one snapshot');
-- Members cannot close or reopen.
select test.act_as(:R);
select test.expect_error(format($$select close_month(%L, '2099-03-10', true)$$, :'mess'), 'NOT_MANAGER');
select test.act_as(null);

-- Backfilled months are labelled reconstructed (same statement as the migration).
insert into months (mess_id, start_date, end_date, status, closed_at) values (:'mess', '2099-01-01', '2099-02-01', 'closed', now()) returning id as jan \gset
update months mo set (food_total, total_meals, meal_rate, extra_total, credit_total) =
  (select t.food_total, t.total_meals, t.meal_rate, t.extra_total, t.credit_total from month_totals_live(mo.mess_id, mo.start_date, mo.end_date) t),
  totals_reconstructed = true where mo.id = :'jan';
select test.check((select totals_reconstructed and food_total is not null from months where id = :'jan'), 'backfill labelled');
select set_config('meal_bazar.today', '', false);
