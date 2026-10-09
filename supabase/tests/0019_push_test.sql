select set_config('meal_bazar.today', '2099-12-31', false);   -- months close only after they end (0032)
-- Push: device token RPCs + RLS, prefs, outbox filled by AFTER triggers for the
-- right recipients in their locale, platform flag, rejected writes enqueue
-- nothing, due reminders, the pg_net kick (stubbed) and the dispatcher claim.
\set M '''19190000-0000-0000-0000-00000000000a'''
\set U '''19190000-0000-0000-0000-00000000000b'''
\set V '''19190000-0000-0000-0000-00000000000c'''
\set P '''19190000-0000-0000-0000-00000000000d'''
\set X '''19190000-0000-0000-0000-00000000000e'''
insert into auth.users (id) values (:M), (:U), (:V), (:P), (:X);
update profiles set locale = 'en' where id = :U;

-- Outbox rows for a user and type (superuser view).
create function test.ob(p_user uuid, p_type text) returns int language sql as $$
  select count(*)::int from public.push_outbox where user_id = p_user and type = p_type;
$$;

select test.act_as(:M);
select create_mess('Push Mess', 'Manager') as mess \gset
select create_invite(:'mess') as code \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :U, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :V, 'Karim');
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = current_date - 1 where mess_id = :'mess';
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset

-- ── device tokens ────────────────────────────────────────────────────────
select test.act_as(:M);
select register_device_token('tok-manager-0001', 'android');
select register_device_token('tok-manager-0001', 'android');   -- idempotent
select test.act_as(:U);
select register_device_token('tok-member-00001', 'android');
select register_device_token('tok-moving-00001', 'android');
select test.expect_error($$select register_device_token('short', 'android')$$, 'check');
select test.expect_error($$select register_device_token('tok-member-00002', 'windows')$$, 'check');
select test.check((select count(*) from device_tokens) = 2, 'member sees only own tokens');
select test.expect_error($$insert into device_tokens (token, user_id, platform) values ('tok-forged-00001', '19190000-0000-0000-0000-00000000000a', 'android')$$, 'row-level security');
-- The moving token is now V's phone: it moves accounts.
select test.act_as(:V);
select register_device_token('tok-moving-00001', 'android');
select test.check((select count(*) from device_tokens) = 1, 'token moved to the new account');
select unregister_device_token('tok-moving-00001');
select test.check((select count(*) from device_tokens) = 0, 'unregistered');
select test.act_as(:U);
select unregister_device_token('tok-manager-0001');   -- not mine: no-op
select test.act_as(null);
select test.check((select count(*) from device_tokens where user_id = :M) = 1, 'cannot unregister another user''s token');

-- ── no client access to the outbox or the helpers ───────────────────────
select test.act_as(:U);
select test.expect_error($$select * from push_outbox$$, 'permission denied');
select test.expect_error($$select push_enqueue(array['19190000-0000-0000-0000-00000000000b'::uuid], 'notice', 'a', 'b', 'c', 'd', '/x')$$, 'permission denied');
select test.expect_error($$select * from push_claim(10)$$, 'permission denied');
select test.expect_error($$select push_kick()$$, 'permission denied');

-- ── join request → managers ──────────────────────────────────────────────
select test.act_as(:P);
select register_device_token('tok-pending-0001', 'android');
select join_mess(:'code', 'Pial') as pial \gset
select test.act_as(null);
select test.check(test.ob(:M, 'join_request') = 1, 'manager told about join request');
select test.check(test.ob(:U, 'join_request') + test.ob(:P, 'join_request') = 0, 'members and requester are not');
select test.check((select title = 'যোগদানের অনুরোধ' and body like 'Pial "Push Mess"%' and data ->> 'route' = '/more/members'
                   from push_outbox where user_id = :M and type = 'join_request'), 'bn text + route');

-- ── bazar → everyone active except the creator, in their locale ─────────
select test.act_as(:M);
insert into bazars (mess_id, date, amount) values (:'mess', current_date, 1250.50);
select test.act_as(null);
select test.check(test.ob(:U, 'bazar_added') = 1 and test.ob(:M, 'bazar_added') = 0, 'bazar: member yes, creator no');
select test.check(test.ob(:V, 'bazar_added') = 0, 'no device, no row');
select test.check(test.ob(:P, 'bazar_added') = 0, 'pending requester gets nothing');
select test.check((select title = 'New bazar' and body = 'Push Mess: ৳1,250.50 bazar added'
                   from push_outbox where user_id = :U and type = 'bazar_added'), 'en text for an en profile');
select test.act_as(:U);
select test.expect_error(format($$insert into bazars (mess_id, date, amount) values (%L, current_date, 80)$$, :'mess'),
                         'row-level security');   -- members may not write bazars …
select test.act_as(null);
select test.check(test.ob(:M, 'bazar_added') = 0, '… so nothing is queued');

-- ── prefs: a type turned off ────────────────────────────────────────────
select test.act_as(:U);
update profiles set notification_prefs = '{"bazar_added": false}' where id = :U;
select test.expect_error($$update profiles set notification_prefs = '[]' where id = '19190000-0000-0000-0000-00000000000b'$$, 'check');
select test.act_as(:M);
select test.check(test.rows(format($$update profiles set notification_prefs = '{}' where id = %L$$, :U)) = 0, 'cannot edit someone else''s prefs');
insert into bazars (mess_id, date, amount) values (:'mess', current_date, 300);
select test.act_as(null);
select test.check(test.ob(:U, 'bazar_added') = 1, 'turned-off type is not queued');
update profiles set notification_prefs = '{}' where id = :U;

-- ── expenses: one push per statement (recurring batch) ──────────────────
select test.act_as(:M);
select id as rent from expense_categories where mess_id = :'mess' and name = 'বাসা ভাড়া' \gset
select id as wifi from expense_categories where mess_id = :'mess' and name = 'ওয়াইফাই' \gset
insert into recurring_expenses (mess_id, category_id, amount, split) values (:'mess', :'rent', 6000, 'meal');
insert into recurring_expenses (mess_id, category_id, amount, split) values (:'mess', :'wifi', 900, 'meal');
select test.check(apply_recurring_expenses(:'mess', current_date) = 2, 'two bills posted');
select test.act_as(null);
select test.check(test.ob(:U, 'expense_added') = 1, 'recurring batch = one push');
select test.check((select body = 'Push Mess: 2 expenses, ৳6,900 total' from push_outbox where user_id = :U and type = 'expense_added'),
                  'batch text');
select test.act_as(:M);
insert into expenses (mess_id, date, category_id, amount, split) values (:'mess', current_date, :'wifi', 300, 'equal');
select test.act_as(null);
select test.check(test.ob(:U, 'expense_added') = 2 and test.ob(:M, 'expense_added') = 0, 'single expense pushed, not to its creator');

-- ── deposits: pending → managers; verified/rejected → the member ────────
select test.act_as(:U);
select record_my_deposit(:'mess', gen_random_uuid(), current_date, 60, 'bkash', null, null, null) as d1 \gset
select record_my_deposit(:'mess', :'d1', current_date, 60, 'bkash', null, null, null);   -- offline retry
select record_my_deposit(:'mess', gen_random_uuid(), current_date, 40, 'cash', null, null, null) as d2 \gset
select test.act_as(null);
select test.check(test.ob(:M, 'deposit_pending') = 2, 'manager told about each pending deposit once');
select test.check((select bool_and(title = 'জমা যাচাই করুন') from push_outbox where user_id = :M and type = 'deposit_pending'), 'bn title');
select test.check(exists (select 1 from push_outbox where user_id = :M and type = 'deposit_pending' and body = 'Rahim ৳৬০ জমা দিয়েছেন'),
                  'Bangla digits in the amount');
select test.act_as(:M);
select verify_deposit(:'d1', true);
select verify_deposit(:'d2', false);
select test.act_as(null);
select test.check(test.ob(:U, 'deposit_verified') = 1 and test.ob(:U, 'deposit_rejected') = 1, 'member told the outcome');
select test.check((select body = 'Your ৳60 deposit was verified' from push_outbox where user_id = :U and type = 'deposit_verified'), 'verified text');

-- ── notice → everyone active except the author ──────────────────────────
select test.act_as(:M);
insert into announcements (mess_id, title, body) values (:'mess', 'পানি বন্ধ', 'কাল সকালে') returning id as n1 \gset
select test.act_as(null);
select test.check(test.ob(:U, 'notice') = 1 and test.ob(:M, 'notice') = 0, 'notice to members, not the author');
select test.check((select title = 'Notice: পানি বন্ধ' and data ->> 'route' = '/more/notices/' || :'n1'
                   from push_outbox where user_id = :U and type = 'notice'), 'notice route');

-- ── platform flag `push` off → nothing queued ───────────────────────────
update platform_config set value = value || '{"push": false}' where key = 'features';
select test.act_as(:M);
insert into announcements (mess_id, title) values (:'mess', 'চুপ');
select test.act_as(null);
select test.check(test.ob(:U, 'notice') = 1, 'flag off: no push');
update platform_config set value = value - 'push' where key = 'features';
select test.check(coalesce(platform_default('features', 'push'), 'true') = 'true'::jsonb, 'missing flag = on');
select test.check((platform_config_defaults() -> 'features' ->> 'push')::boolean, 'push in the defaults');

-- ── due reminders (manager; member_balances; throttled) ─────────────────
-- Rahim: a third of the 300 equal expense (bills are meal-split, no meals yet) minus 60 verified = owes 40.
select test.act_as(:U);
select test.expect_error(format($$select send_due_reminders(%L)$$, :'mess'), 'NOT_MANAGER');
select test.act_as(:M);
select send_due_reminders(:'mess') as sent \gset
select test.check(:sent = 1, 'one member with a device owes money');
select test.expect_error(format($$select send_due_reminders(%L)$$, :'mess'), 'TOO_SOON');
select test.act_as(null);
select test.check((select data ->> 'route' = '/money' and body = 'Push Mess: you owe ৳40, please deposit'
                   from push_outbox where user_id = :U and type = 'due_reminder'), 'due text in en');
select test.check((select closing_balance from member_balances(:'mess', (select start_date from month_period(:'mess', current_date)),
                                                               (select end_date from month_period(:'mess', current_date)))
                   where member_id = :'rahim') = -40, 'due amount comes from member_balances');
select test.check(test.ob(:M, 'due_reminder') = 0, 'the caller is not reminded');
select test.check((select (new ->> 'notified')::int = 1 from audit_log where mess_id = :'mess' and action = 'send_due_reminders'), 'audited');

-- ── month close → every active member (closer too) ──────────────────────
select test.act_as(:M);
select close_month(:'mess', current_date, true);
select test.act_as(null);
select test.check(test.ob(:U, 'month_closed') = 1 and test.ob(:M, 'month_closed') = 1, 'month closed pushed to all');

-- ── rejected writes enqueue nothing ─────────────────────────────────────
select count(*) as before from push_outbox \gset
select test.act_as(:M);
select test.expect_error(format($$insert into bazars (mess_id, date, amount) values (%L, current_date, 10)$$, :'mess'), 'MONTH_CLOSED');
select test.act_as(null);
insert into platform_admins (user_id) values (:X);
select test.act_as(:X);
select admin_set_mess_suspended(:'mess', true, 'test');
select test.act_as(:M);
select test.expect_error(format($$insert into announcements (mess_id, title) values (%L, 'x')$$, :'mess'), 'MESS_SUSPENDED');
select test.expect_error(format($$select send_due_reminders(%L)$$, :'mess'), 'MESS_SUSPENDED');
select test.act_as(:X);
select admin_set_mess_suspended(:'mess', false, null);
select test.act_as(null);
select test.check((select count(*) from push_outbox) = :before, 'nothing queued for rejected writes');

-- ── kick: one pg_net call per transaction, only with both secrets ───────
create schema net;
create table net.calls (url text, headers jsonb);
create function net.http_post(url text, body jsonb default '{}', params jsonb default '{}',
                              headers jsonb default '{}', timeout_milliseconds int default 5000)
returns bigint language sql as $$ insert into net.calls values (url, headers) returning 1::bigint $$;
select test.act_as(:M);
insert into announcements (mess_id, title) values (:'mess', 'no secrets');
select test.act_as(null);
select test.check((select count(*) from net.calls) = 0, 'no secrets: no kick');
insert into platform_secrets (name, value)
values ('PUSH_GATEWAY_URL', 'https://gw.example.com/'), ('PUSH_DISPATCH_SECRET', 'shh-secret-value');
select test.act_as(:M);
begin;
insert into announcements (mess_id, title) values (:'mess', 'one');
insert into announcements (mess_id, title) values (:'mess', 'two');
commit;
select test.act_as(null);
select test.check((select count(*) from net.calls) = 1, 'one kick per transaction');
select test.check((select url = 'https://gw.example.com/api/push/dispatch' and headers ->> 'x-push-secret' = 'shh-secret-value'
                   from net.calls), 'kick url + secret header');
create or replace function net.http_post(url text, body jsonb default '{}', params jsonb default '{}',
                                         headers jsonb default '{}', timeout_milliseconds int default 5000)
returns bigint language plpgsql as $$ begin raise exception 'net down'; end $$;
select test.act_as(:M);
set client_min_messages = error;   -- the expected push_kick warning
insert into announcements (mess_id, title) values (:'mess', 'kick fails, write stays');
select test.act_as(null);
select test.check(exists (select 1 from announcements where title = 'kick fails, write stays'), 'a failed kick never fails the write');
drop schema net cascade;
reset client_min_messages;

-- ── dispatcher claim (service role) ─────────────────────────────────────
select count(*) as unsent from push_outbox where sent_at is null \gset
set role service_role;
create temp table claimed as select * from push_claim(500);
reset role;
select test.check((select count(*) from claimed) = :unsent, 'claims every unsent row');
select test.check((select bool_and(tokens = array['tok-manager-0001']) from claimed where user_id = :M), 'with the recipient''s tokens');
select test.check((select bool_and(attempts = 1 and claimed_at is not null) from push_outbox), 'attempt counted');
set role service_role;
select count(*) as again from push_claim(500) \gset
reset role;
select test.check(:again = 0, 'claimed rows are not handed out twice');
update push_outbox set claimed_at = now() - interval '3 minutes', attempts = 5 where user_id = :M;
update push_outbox set claimed_at = now() - interval '3 minutes' where user_id = :U;
set role service_role;
select count(*) as retried from push_claim(500) \gset
reset role;
select test.check(:retried = (select count(*) from push_outbox where user_id = :U),
                  'abandoned claims retry; 5 attempts is the limit');

-- ── account deletion forgets devices and queued pushes ──────────────────
select test.act_as(:U);
select delete_my_account();
select test.act_as(null);
select test.check((select count(*) from device_tokens where user_id = :U) = 0, 'tokens gone');
select test.check((select count(*) from push_outbox where user_id = :U) = 0, 'queued pushes gone');
