select set_config('meal_bazar.today', '2099-12-31', false);   -- months close only after they end (0032)
-- Recurring monthly bills (apply once per period, inactive skipped, closed
-- month refused) and member default meals used by fill_meals_for_day.
\set M '''15151515-0000-0000-0000-00000000000a'''
\set R '''15151515-0000-0000-0000-00000000000b'''
\set X '''15151515-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:X);

select test.act_as(:M);
select create_mess('Recurring Mess', 'Manager') as mess \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select create_invite(:'mess') as code \gset
select test.act_as(:R);
select join_mess(:'code', 'Rahim') as rahim \gset
select test.act_as(:M);
update mess_members set status = 'active' where id = :'rahim';
update mess_members set joined_on = '2026-10-01' where mess_id = :'mess';
select id as rent from expense_categories where mess_id = :'mess' and name = 'বাসা ভাড়া' \gset
select id as wifi from expense_categories where mess_id = :'mess' and name = 'ওয়াইফাই' \gset
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
select id as dinner from meal_types where mess_id = :'mess' and name = 'রাত' \gset

-- Constraints.
select test.expect_error(format($$insert into recurring_expenses (mess_id, category_id, amount, split, day_of_period) values (%L, %L, 10, 'equal', 29)$$, :'mess', :'rent'), 'check');
select test.expect_error(format($$insert into recurring_expenses (mess_id, category_id, amount, split) values (%L, %L, -1, 'equal')$$, :'mess', :'rent'), 'check');
select test.expect_error(format($$insert into meal_defaults (mess_id, member_id, meal_type_id, count) values (%L, %L, %L, 0.3)$$, :'mess', :'rahim', :'lunch'), 'check');

insert into recurring_expenses (mess_id, category_id, amount, split, day_of_period, note)
values (:'mess', :'rent', 12000, 'equal', 5, 'ভাড়া') returning id as rent_bill \gset
insert into recurring_expenses (mess_id, category_id, amount, split)
values (:'mess', :'wifi', 1000, 'equal') returning id as wifi_bill \gset
insert into recurring_expenses (mess_id, category_id, amount, split, active)
values (:'mess', :'wifi', 999, 'meal', false);

-- Apply: one expense per active bill, dated start + day − 1; idempotent.
select test.check(pending_recurring_count(:'mess', '2026-10-20') = 2, 'two bills pending');
select test.check(apply_recurring_expenses(:'mess', '2026-10-20') = 2, 'apply creates active bills only');
select test.check(apply_recurring_expenses(:'mess', '2026-10-31') = 0, 'apply is idempotent in the period');
select test.check(pending_recurring_count(:'mess', '2026-10-20') = 0, 'nothing pending after apply');
select test.check((select count(*) from expenses where mess_id = :'mess') = 2, 'two expenses');
select test.check((select date = '2026-10-05' and amount = 12000 and split = 'equal' and source = 'system' and note = 'ভাড়া'
                   from expenses where category_id = :'rent'), 'rent dated day 5');
select test.check((select date from expenses where amount = 1000) = '2026-10-01', 'wifi dated period start');
-- Deleting the posted expense does not make it post again this period.
update expenses set deleted_at = now() where amount = 1000;
select test.check(apply_recurring_expenses(:'mess', '2026-10-02') = 0, 'deleted expense not re-posted');
-- Next period applies again, honouring month_start_day.
update messes set month_start_day = 10 where id = :'mess';
select test.check(apply_recurring_expenses(:'mess', '2026-11-15') = 2, 'next period applies again');
select test.check((select date from expenses where category_id = :'rent' and date > '2026-10-05') = '2026-11-14', 'rent dated start(10) + 4');
update messes set month_start_day = 1 where id = :'mess';

-- Closed month: a newly added bill cannot be posted into it.
select close_month(:'mess', '2026-10-01', true) as oct \gset
update recurring_expenses set active = true where amount = 999;
select test.expect_error(format($$select apply_recurring_expenses(%L, '2026-10-15')$$, :'mess'), 'MONTH_CLOSED');
select test.check((select count(*) from recurring_applied where period_start = '2026-10-01') = 2, 'refused apply leaves no mark');

-- Fill: yesterday wins, else member default, else 1.
insert into meal_defaults (mess_id, member_id, meal_type_id, count) values
  (:'mess', :'rahim', :'lunch', 0), (:'mess', :'rahim', :'dinner', 1.5);
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
values (:'mess', :'rahim', :'dinner', '2026-12-09', 2);
select test.check(fill_meals_for_day(:'mess', '2026-12-10') = 4, 'fill 2 members × 2 enabled types');
select test.check((select count from meal_entries where member_id = :'rahim' and meal_type_id = :'lunch' and date = '2026-12-10') = 0, 'default used when no yesterday');
select test.check((select count from meal_entries where member_id = :'rahim' and meal_type_id = :'dinner' and date = '2026-12-10') = 2, 'yesterday beats default');
select test.check((select count from meal_entries where member_id = :'mgr' and meal_type_id = :'lunch' and date = '2026-12-10') = 1, 'no default → 1');

-- RLS: members read, only managers write or apply; outsiders see nothing.
select test.act_as(:R);
select test.check((select count(*) from recurring_expenses) = 3, 'member reads bills');
select test.check((select count(*) from meal_defaults) = 2, 'member reads defaults');
select test.check(test.rows(format($$update recurring_expenses set amount = 1 where mess_id = %L$$, :'mess')) = 0, 'member cannot edit bills');
select test.expect_error(format($$insert into meal_defaults (mess_id, member_id, meal_type_id, count) values (%L, %L, %L, 1)$$, :'mess', :'mgr', :'lunch'), 'row-level security');
select test.expect_error(format($$select apply_recurring_expenses(%L, '2026-12-01')$$, :'mess'), 'NOT_MANAGER');
select test.act_as(:X);
select test.check((select count(*) from recurring_expenses) + (select count(*) from recurring_applied) + (select count(*) from meal_defaults) = 0, 'outsider sees nothing');
select test.check(pending_recurring_count(:'mess', '2026-12-01') = 0, 'outsider pending count 0');
select test.act_as(null);
