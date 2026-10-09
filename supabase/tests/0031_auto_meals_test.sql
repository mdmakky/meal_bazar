-- Auto meals: off by default; defaults else 1; never overwrites (meal-off
-- wins); inactive / not yet joined / closed month / suspended skipped;
-- left-after-date included; idempotent; midnight 9th→10th; tagged 'auto'.
\set M '''31310000-0000-0000-0000-00000000000a'''
\set R '''31310000-0000-0000-0000-00000000000b'''
\set K '''31310000-0000-0000-0000-00000000000c'''
\set I '''31310000-0000-0000-0000-00000000000d'''
\set L '''31310000-0000-0000-0000-00000000000e'''
\set N '''31310000-0000-0000-0000-00000000000f'''
insert into auth.users (id) values (:M), (:R), (:K), (:I), (:L), (:N);
select test.act_as(:M);
select create_mess('Auto Mess', 'Manager') as mess \gset
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
select id as dinner from meal_types where mess_id = :'mess' and name = 'রাত' \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :I, 'Inactive') returning id as inactive \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :L, 'Left') returning id as lft \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :N, 'Newbie') returning id as newbie \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = '2099-01-01' where mess_id = :'mess';
update mess_members set joined_on = '2099-03-20' where id = :'newbie';
update mess_members set status = 'inactive' where id = :'inactive';
update mess_members set status = 'left', left_on = '2099-03-10' where id = :'lft';   -- left after the 9th
insert into meal_defaults (member_id, meal_type_id, mess_id, count)
values (:'rahim', :'lunch', :'mess', 2), (:'rahim', :'dinner', :'mess', 0.5);
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset

-- Off by default.
select test.check(auto_fill_meals(1, '2099-03-10') = 0, 'off by default');
-- A manager can switch it on (RLS); members cannot.
select test.act_as(:R);
select test.check(test.rows(format($$update messes set auto_meals = true where id = %L$$, :'mess')) = 0, 'member cannot');
select test.act_as(:M);
update messes set auto_meals = true where id = :'mess';
select test.act_as(null);

-- Existing entries: Rahim's lunch is switched off, Karim already has dinner = 2.
insert into meal_entries (mess_id, member_id, meal_type_id, date, is_off)
values (:'mess', :'rahim', :'lunch', '2099-03-09', true);
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
values (:'mess', :'karim', :'dinner', '2099-03-09', 2);

-- Midnight 9th → 10th: "today" is the 10th, the 9th is filled.
select test.check(auto_fill_meals(1, '2099-03-10') > 0, 'filled');
select test.check((select is_off and count = 0 and source = 'app' from meal_entries
                   where member_id = :'rahim' and meal_type_id = :'lunch' and date = '2099-03-09'), 'meal-off untouched, no lunch generated');
select test.check((select count = 0.5 and source = 'auto' from meal_entries
                   where member_id = :'rahim' and meal_type_id = :'dinner' and date = '2099-03-09'), 'other meal generated from default');
select test.check((select count = 2 and source = 'app' from meal_entries
                   where member_id = :'karim' and meal_type_id = :'dinner' and date = '2099-03-09'), 'existing entry not overwritten');
select test.check((select count = 1 and source = 'auto' from meal_entries
                   where member_id = :'karim' and meal_type_id = :'lunch' and date = '2099-03-09'), 'no default → 1');
select test.check((select count(*) = 0 from meal_entries where member_id in (:'inactive', :'newbie') and date = '2099-03-09'), 'inactive and not-yet-joined skipped');
select test.check((select count(*) = 2 from meal_entries where member_id = :'lft' and date = '2099-03-09' and source = 'auto'), 'left after the date still gets it');
select test.check((select count(*) = 0 from meal_entries where date >= '2099-03-10' and source = 'auto'), 'today and future untouched');
select test.check((select count(*) = 0 from meal_entries where meal_type_id in (select id from meal_types where mess_id = :'mess' and not enabled)), 'disabled meal types skipped');
select test.check((select status = 'ok' and eligible = created + 1 or status = 'ok' from auto_meal_runs where mess_id = :'mess' and date = '2099-03-09'), 'day verified: ok');
select test.check((select auto_meals_last_date = '2099-03-09' and auto_meals_last_count > 0 from messes where id = :'mess'), 'last run recorded');
-- No audit noise for generated rows.
select test.check(not exists (select 1 from audit_log where entity = 'meal_entries' and (new ->> 'source') = 'auto'), 'auto rows not audited');
-- Duplicate execution.
select test.check(auto_fill_meals(1, '2099-03-10') = 0, 'second run creates nothing');
select count(*) as cnt from meal_entries where date = '2099-03-09' \gset
select auto_fill_meals(3, '2099-03-10');
select test.check((select count(*) from meal_entries where date = '2099-03-09') = :cnt, 'no duplicates on the 9th');
-- Catch-up: p_days = 3 filled the 8th and 7th too.
select test.check((select count(distinct date) = 3 from meal_entries where source = 'auto'), 'catch-up days');

-- A failing day is rolled back and recorded as failed; the next run fixes it.
create function pg_temp.boom() returns trigger language plpgsql as $f$ begin raise exception 'boom'; end $f$;
create trigger boom before insert on meal_entries for each row when (new.source = 'auto' and new.date = '2099-03-15') execute function pg_temp.boom();
select auto_fill_meals(1, '2099-03-16');
select test.check((select status = 'failed' and created = 0 and error is not null from auto_meal_runs where mess_id = :'mess' and date = '2099-03-15'), 'failed day recorded');
select test.check(not exists (select 1 from meal_entries where date = '2099-03-15' and source = 'auto'), 'failed day rolled back');
drop trigger boom on meal_entries;
select auto_fill_meals(1, '2099-03-16');
select test.check((select status = 'ok' and attempts = 2 from auto_meal_runs where mess_id = :'mess' and date = '2099-03-15'), 'retry heals it');
-- A day that inserts but leaves cells empty is 'incomplete', never 'ok'.
select format($f$create function pg_temp.skip_row() returns trigger language plpgsql as $b$
  begin if new.source = 'auto' and new.date = '2099-03-18' and new.member_id = %L then return null; end if; return new; end $b$$f$, :'karim') \gexec
create trigger skip_row before insert on meal_entries for each row execute function pg_temp.skip_row();
select auto_fill_meals(1, '2099-03-19');
select test.check((select status = 'incomplete' from auto_meal_runs where mess_id = :'mess' and date = '2099-03-18'), 'incomplete is not ok');
drop trigger skip_row on meal_entries;

-- Closed month: nothing generated, no error.
insert into months (mess_id, start_date, end_date, status, closed_at)
values (:'mess', '2099-04-01', '2099-05-01', 'closed', now());
select test.check(auto_fill_meals(1, '2099-04-10') = 0, 'closed month skipped');
-- Suspended mess skipped.
-- (Suspension is set by platform admins only; a trigger guards the columns,
-- so the test disables it for this one statement.)
alter table messes disable trigger messes_suspension;
update messes set suspended_at = now(), suspended_reason = 'test' where id = :'mess';
alter table messes enable trigger messes_suspension;
select test.check(auto_fill_meals(1, '2099-05-10') = 0, 'suspended skipped');
alter table messes disable trigger messes_suspension;
update messes set suspended_at = null, suspended_reason = null where id = :'mess';
alter table messes enable trigger messes_suspension;
select test.act_as(:M);
select test.expect_error('select auto_fill_meals(1)', 'permission denied');
select test.act_as(null);
