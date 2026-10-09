-- Meal-off deadline: per-meal serve time − mess lead (null lead = previous-day
-- cutoff), managers unrestricted; member switches post one (collapsing)
-- system notice into the mess group, never for manager edits; flags.
\set M '''24240000-0000-0000-0000-00000000000a'''
\set R '''24240000-0000-0000-0000-00000000000b'''
\set V '''24240000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:V);

select test.act_as(:M);
select create_mess('Deadline Mess', 'Manager') as mess \gset
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
select id as dinner from meal_types where mess_id = :'mess' and name = 'রাত' \gset
select id as bf from meal_types where mess_id = :'mess' and name = 'সকাল' \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'তানভীর') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :V, 'Karim');
select set_config('meal_bazar.trusted', '', false);
insert into device_tokens (token, user_id, platform) values ('tok-deadline-mgr-1', :M, 'android'),
  ('tok-deadline-mem-1', :R, 'android'), ('tok-deadline-mem-2', :V, 'android');

-- ── serve times: seeded by name, filled for new types, manager-editable ──
select test.check((select serve_time = '08:00' from meal_types where id = :'bf')
              and (select serve_time = '13:30' from meal_types where id = :'lunch')
              and (select serve_time = '21:00' from meal_types where id = :'dinner'), 'serve times by name');
select test.act_as(:M);
insert into meal_types (mess_id, name, sort_order) values (:'mess', 'নাস্তা', 5) returning serve_time = '13:00' as other_ok \gset
select test.check(:'other_ok', 'other names default to 13:00');
select test.check((select meal_off_lead_minutes is null from messes where id = :'mess'), 'lead null by default (old rule)');
select test.expect_error(format($$update messes set meal_off_lead_minutes = 2881 where id = %L$$, :'mess'), 'check');
select test.expect_error(format($$update messes set meal_off_lead_minutes = -1 where id = %L$$, :'mess'), 'check');

-- ── deadline math (Asia/Dhaka = UTC+6) ───────────────────────────────────
-- Old rule: previous day at the cutoff.
select test.check(meal_off_deadline(:'mess', '2099-03-01', :'dinner') = '2099-02-28 22:00+06', 'legacy: previous day 22:00');
update messes set meal_off_lead_minutes = 120 where id = :'mess';
select test.check(meal_off_deadline(:'mess', '2099-03-01', :'dinner') = '2099-03-01 19:00+06', 'same day: 2 h before 21:00');
update messes set meal_off_lead_minutes = 0 where id = :'mess';
select test.check(meal_off_deadline(:'mess', '2099-03-01', :'dinner') = '2099-03-01 21:00+06', '0 lead: right up to serve time');
update messes set meal_off_lead_minutes = 1440 where id = :'mess';
select test.check(meal_off_deadline(:'mess', '2099-03-01', :'lunch') = '2099-02-28 13:30+06', '1440: a day before');
-- Around Dhaka midnight: 00:30 meal, 1 h lead → 23:30 the day before (17:30 UTC).
update meal_types set serve_time = '00:30' where id = :'bf';
update messes set meal_off_lead_minutes = 60 where id = :'mess';
select test.check(meal_off_deadline(:'mess', '2099-03-01', :'bf') = '2099-02-28 17:30+00', 'midnight crossing in Dhaka');
select test.check((select count(*) = 8 and bool_and(deadline is not null)
                   from meal_off_deadlines(:'mess', '2099-03-01', '2099-03-02')), 'set-returning: 2 days × 4 types');
select test.check((select deadline = '2099-03-01 20:00+06' from meal_off_deadlines(:'mess', '2099-03-01', '2099-03-01')
                   where meal_type_id = :'dinner'), 'set-returning matches');
select test.act_as(:'rahim'::uuid);   -- not a user: RLS hides the mess
select test.check(meal_off_deadline(:'mess', '2099-03-01', :'dinner') is null, 'outsiders see no deadline');
select test.act_as(:R);
select test.check(meal_off_deadline(:'mess', '2099-03-01', :'dinner') is not null, 'members read it');

-- ── enforcement ──────────────────────────────────────────────────────────
-- Past the deadline: refused for members (yesterday's dinner).
select test.expect_error(format($$select set_my_meal_off(%L, (now() at time zone 'Asia/Dhaka')::date - 1, %L, true)$$, :'mess', :'dinner'), 'CUTOFF_PASSED');
-- Same day is allowed with a lead: today's meal served 23:59:59, 0 lead.
select test.act_as(:M);
update messes set meal_off_lead_minutes = 0 where id = :'mess';
update meal_types set serve_time = '23:59:59' where id = :'lunch';
select test.act_as(:R);
do $$
begin
  if (now() at time zone 'Asia/Dhaka')::time < '23:58' then
    perform set_my_meal_off((select id from messes where name = 'Deadline Mess'),
                            (now() at time zone 'Asia/Dhaka')::date,
                            (select t.id from meal_types t join messes m on m.id = t.mess_id
                             where m.name = 'Deadline Mess' and t.name = 'দুপুর'), true);
    perform test.check((select bool_or(is_off) from meal_entries where date = (now() at time zone 'Asia/Dhaka')::date),
                       'same-day switch before serve time');
  end if;
end $$;
-- Managers are never restricted by the deadline.
select test.act_as(:M);
select set_my_meal_off(:'mess', (now() at time zone 'Asia/Dhaka')::date - 1, :'dinner', true);
select test.check((select is_off from meal_entries where member_id = :'mgr' and meal_type_id = :'dinner'), 'manager past the deadline');
update meal_types set serve_time = '13:30' where id = :'lunch';
update messes set meal_off_lead_minutes = 120 where id = :'mess';

-- ── the group notice ─────────────────────────────────────────────────────
select test.act_as(null);
delete from messages;
delete from push_outbox;
select test.act_as(:R);
select set_my_meal_off(:'mess', '2099-03-01', :'dinner', true);
select test.act_as(null);
select id as grp from message_threads where mess_id = :'mess' and kind = 'group' \gset
select test.check((select count(*) = 1 from messages where thread_id = :'grp' and kind = 'system'), 'one notice');
select test.check((select sender_id = :R and body = '০১/০৩ রাতের মিল বন্ধ করেছেন'
                          and meta ->> 'name' = 'তানভীর' and (meta ->> 'off')::boolean
                          and meta ->> 'date' = '2099-03-01' and meta ->> 'meal' = :'dinner'
                   from messages where thread_id = :'grp'), 'notice text and payload');
select test.check((select count(*) from push_outbox where type = 'group_message') = 2
                  and not exists (select 1 from push_outbox where user_id = :R), 'group push to the others');
-- Same state again: no new notice.
select test.act_as(:R);
select set_my_meal_off(:'mess', '2099-03-01', :'dinner', true);
-- Flip back within 2 minutes: the notice is replaced, not added.
select set_my_meal_off(:'mess', '2099-03-01', :'dinner', false);
select test.act_as(null);
select test.check((select count(*) = 1 from messages where thread_id = :'grp'), 'flip-flop collapses');
select test.check((select body = '০১/০৩ রাতের মিল আবার চালু করেছেন' and not (meta ->> 'off')::boolean
                   from messages where thread_id = :'grp'), 'latest state wins');
-- Older than 2 minutes, or another meal: a new notice.
update messages set created_at = created_at - interval '3 minutes' where thread_id = :'grp';
select test.act_as(:R);
select set_my_meal_off(:'mess', '2099-03-01', :'dinner', true);
select set_my_meal_off(:'mess', '2099-03-01', :'lunch', true);
select test.act_as(null);
select test.check((select count(*) = 3 from messages where thread_id = :'grp'), 'new notices after 2 min / other meal');
select test.check((select body = '০১/০৩ দুপুরের মিল বন্ধ করেছেন' from messages
                   where thread_id = :'grp' and meta ->> 'meal' = :'lunch'), 'genitive দুপুরের');
select test.check(bn_genitive('নাস্তা') = 'নাস্তার' and bn_genitive('Lunch') = 'Lunch-এর', 'genitive forms');
-- Day words relative to Dhaka today.
select test.act_as(:R);
select set_my_meal_off(:'mess', (now() at time zone 'Asia/Dhaka')::date + 1, :'dinner', true);
select test.act_as(null);
select test.check(exists (select 1 from messages where body = 'কাল রাতের মিল বন্ধ করেছেন'), 'tomorrow = কাল');

-- Manager edits (direct writes) and the daily fill never post.
select count(*) as before from messages \gset
select test.act_as(:M);
update meal_entries set is_off = false where member_id = :'rahim' and date = '2099-03-01' and meal_type_id = :'dinner';
insert into meal_entries (mess_id, member_id, meal_type_id, date, is_off) values (:'mess', :'rahim', :'dinner', '2099-03-05', true);
select fill_meals_for_day(:'mess', '2099-03-06');
select test.act_as(null);
select test.check((select count(*) from messages) = :before, 'no notice for manager edits or fill');

-- Clients cannot post notices themselves.
select test.act_as(:R);
select test.expect_error(format($$select post_meal_off_notice(%L, %L, '2099-03-01', %L, true)$$, :'mess', :'rahim', :'dinner'), 'permission denied');

-- ── flags ────────────────────────────────────────────────────────────────
select test.act_as(null);
update platform_config set value = value || '{"mess_group": false}' where key = 'features';
select test.act_as(:R);
select set_my_meal_off(:'mess', '2099-03-10', :'dinner', true);
select test.act_as(null);
update platform_config set value = value - 'mess_group' || '{"messages": false}' where key = 'features';
select test.act_as(:R);
select set_my_meal_off(:'mess', '2099-03-11', :'dinner', true);
select test.act_as(null);
select test.check((select count(*) from messages) = :before, 'no notice when mess_group or messages is off');
select test.check((select count(*) from meal_entries where member_id = :'rahim' and date in ('2099-03-10', '2099-03-11') and is_off) = 2, 'the switch itself still saves');
update platform_config set value = value - 'messages' || '{"member_meal_off": false}' where key = 'features';
select test.act_as(:R);
select test.expect_error(format($$select set_my_meal_off(%L, '2099-03-12', %L, true)$$, :'mess', :'dinner'), 'FEATURE_OFF');
select test.act_as(:M);
select set_my_meal_off(:'mess', '2099-03-12', :'dinner', true);   -- managers unaffected
select test.act_as(null);
update platform_config set value = value - 'member_meal_off' where key = 'features';
