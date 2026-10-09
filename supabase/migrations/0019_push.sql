-- 0019_push: FCM push notifications. Device tokens, per-user notification
-- prefs, and an outbox that AFTER triggers fill (so a write the guards reject
-- never notifies anyone). The gateway (`/api/push/dispatch`) sends the outbox;
-- pg_net pokes it after each enqueue and the daily cron drains leftovers.
-- Contract: DATABASE.md "Push (0019)".

-- ── device tokens ────────────────────────────────────────────────────────
create table public.device_tokens (
  token      text primary key check (char_length(token) between 10 and 4096),
  user_id    uuid not null references auth.users(id) on delete cascade,
  platform   text not null check (platform in ('android', 'ios', 'web')),
  updated_at timestamptz not null default now()
);
create index device_tokens_user_idx on public.device_tokens(user_id);
alter table public.device_tokens enable row level security;
-- Writes go through the RPCs below (a token may move between accounts).
create policy device_tokens_read on public.device_tokens for select using (user_id = auth.uid());
create policy device_tokens_delete on public.device_tokens for delete using (user_id = auth.uid());

-- Upsert; a token that was registered to another account (same phone, new
-- login) moves to the caller.
create or replace function public.register_device_token(p_token text, p_platform text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := require_user();
begin
  insert into device_tokens (token, user_id, platform, updated_at)
  values (btrim(p_token), v_uid, p_platform, now())
  on conflict (token) do update
    set user_id = excluded.user_id, platform = excluded.platform, updated_at = now();
end $$;

create or replace function public.unregister_device_token(p_token text) returns void
language sql security definer set search_path = public as $$
  delete from device_tokens where token = btrim(p_token) and user_id = auth.uid();
$$;

-- ── prefs: {type: false} turns a type off; a missing key is on ───────────
alter table public.profiles
  add column notification_prefs jsonb not null default '{}'
  check (jsonb_typeof(notification_prefs) = 'object');

-- ── outbox (no client access; service role via push_claim) ───────────────
create table public.push_outbox (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  type       text not null,
  title      text not null,            -- already in the recipient's locale
  body       text not null,
  data       jsonb not null default '{}',   -- {route, type}
  created_at timestamptz not null default now(),
  claimed_at timestamptz,
  sent_at    timestamptz,
  attempts   int not null default 0,
  last_error text
);
create index push_outbox_unsent_idx on public.push_outbox(id) where sent_at is null;
alter table public.push_outbox enable row level security;   -- no policies
revoke all on public.push_outbox from public, anon, authenticated;

-- ── platform: `push` flag (missing = on) and the dispatch credentials ────
alter function public.platform_config_defaults() rename to platform_config_defaults_0017;
create function public.platform_config_defaults() returns jsonb
language sql immutable as $$
  select jsonb_set(platform_config_defaults_0017(), '{features,push}', 'true');
$$;
update public.platform_config set value = value || '{"push":true}'
where key = 'features' and not value ? 'push';

-- PUSH_GATEWAY_URL (e.g. https://<gateway>.vercel.app) and PUSH_DISPATCH_SECRET
-- (the same value as the gateway env var) let the DB poke the dispatcher.
alter table public.platform_secrets drop constraint platform_secrets_name_check;
alter table public.platform_secrets add constraint platform_secrets_name_check
  check (name in ('GEMINI_API_KEY', 'OPENROUTER_API_KEY', 'SMS_PROVIDER_KEY', 'SMTP_PASSWORD',
                  'PUSH_GATEWAY_URL', 'PUSH_DISPATCH_SECRET'));

create or replace function public.admin_set_secret(p_name text, p_value text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := require_platform_admin();
begin
  if p_name is null or p_name not in ('GEMINI_API_KEY', 'OPENROUTER_API_KEY', 'SMS_PROVIDER_KEY', 'SMTP_PASSWORD',
                                      'PUSH_GATEWAY_URL', 'PUSH_DISPATCH_SECRET') then
    perform fail('INVALID_SECRET_NAME');
  end if;
  if coalesce(btrim(p_value), '') = '' then
    delete from platform_secrets where name = p_name;
    perform platform_log('delete_secret', p_name, null, null);
  else
    insert into platform_secrets (name, value, updated_at, updated_by)
    values (p_name, btrim(p_value), now(), v_uid)
    on conflict (name) do update set value = excluded.value, updated_at = now(), updated_by = v_uid;
    perform platform_log('set_secret', p_name, null, null);
  end if;
end $$;

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net;
  end if;
end $$;

-- ── enqueue ──────────────────────────────────────────────────────────────
create or replace function public.push_money(p_amount numeric, p_bn boolean) returns text
language sql immutable as $$
  select '৳' || case when p_bn then translate(trim_scale(round(p_amount, 2))::text, '0123456789', '০১২৩৪৫৬৭৮৯')
                     else trim_scale(round(p_amount, 2))::text end;
$$;

-- Active app users of a mess, optionally one role, minus one user (the actor).
create or replace function public.push_mess_users(p_mess uuid, p_role public.member_role, p_except uuid)
returns uuid[]
language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(user_id), '{}') from mess_members
  where mess_id = p_mess and status = 'active' and user_id is not null
    and (p_role is null or role = p_role) and user_id is distinct from p_except;
$$;

-- Pokes the gateway once per transaction (pg_net sends after commit). A no-op
-- without pg_net or the two secrets; never fails the business write.
create or replace function public.push_kick() returns void
language plpgsql security definer set search_path = public as $$
declare
  v_url    text;
  v_secret text;
begin
  if coalesce(current_setting('meal_bazar.push_kicked', true), '') = 'on'
     or to_regnamespace('net') is null then
    return;
  end if;
  select value into v_url from platform_secrets where name = 'PUSH_GATEWAY_URL';
  select value into v_secret from platform_secrets where name = 'PUSH_DISPATCH_SECRET';
  if v_url is null or v_secret is null then
    return;
  end if;
  perform set_config('meal_bazar.push_kicked', 'on', true);
  perform net.http_post(
    url := rtrim(v_url, '/') || '/api/push/dispatch',
    body := '{}'::jsonb,
    headers := jsonb_build_object('content-type', 'application/json', 'x-push-secret', v_secret),
    timeout_milliseconds := 5000);
exception when others then
  raise warning 'push_kick failed: %', sqlstate;   -- the cron drains it later
end $$;

-- Queues one notification per recipient that is not deleted, has the type on
-- and has a device. Texts are picked by profiles.locale (bn default).
-- Returns how many were queued; 0 when the platform `push` flag is off.
create or replace function public.push_enqueue(
  p_users uuid[], p_type text, p_title_bn text, p_body_bn text, p_title_en text, p_body_en text,
  p_route text
) returns int
language plpgsql security definer set search_path = public as $$
declare
  n int;
begin
  if coalesce(platform_default('features', 'push'), 'true') = 'false'::jsonb
     or coalesce(cardinality(p_users), 0) = 0 then
    return 0;
  end if;
  insert into push_outbox (user_id, type, title, body, data)
  select p.id, p_type,
         case when p.locale = 'en' then p_title_en else p_title_bn end,
         left(case when p.locale = 'en' then p_body_en else p_body_bn end, 240),
         jsonb_build_object('route', p_route, 'type', p_type)
  from profiles p
  where p.id = any (p_users) and p.deleted_at is null
    and coalesce(p.notification_prefs ->> p_type, 'true') <> 'false'
    and exists (select 1 from device_tokens t where t.user_id = p.id);
  get diagnostics n = row_count;
  if n > 0 then
    perform push_kick();
  end if;
  return n;
end $$;

-- ── triggers (AFTER: guards already passed) ──────────────────────────────
create or replace function public.push_on_member() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_mess text;
begin
  if new.status = 'pending' and (tg_op = 'INSERT' or old.status <> 'pending') then
    select name into v_mess from messes where id = new.mess_id;
    perform push_enqueue(push_mess_users(new.mess_id, 'manager', new.user_id), 'join_request',
      'যোগদানের অনুরোধ', format('%s "%s" মেসে যোগ দিতে চান', new.display_name, v_mess),
      'Join request', format('%s wants to join %s', new.display_name, v_mess),
      '/more/members');
  end if;
  return null;
end $$;
create trigger mess_members_push after insert or update of status on public.mess_members
  for each row execute function public.push_on_member();

create or replace function public.push_on_deposit() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  m mess_members%rowtype;
begin
  if new.deleted_at is not null then
    return null;
  end if;
  select * into m from mess_members where id = new.member_id;
  if tg_op = 'INSERT' and new.status = 'pending' then
    perform push_enqueue(push_mess_users(new.mess_id, 'manager', auth.uid()), 'deposit_pending',
      'জমা যাচাই করুন', format('%s %s জমা দিয়েছেন', m.display_name, push_money(new.amount, true)),
      'Deposit to verify', format('%s deposited %s', m.display_name, push_money(new.amount, false)),
      '/money');
  elsif tg_op = 'UPDATE' and old.status = 'pending' and new.status <> 'pending'
        and m.user_id is distinct from auth.uid() then
    if new.status = 'verified' then
      perform push_enqueue(array[m.user_id], 'deposit_verified',
        'জমা গৃহীত হয়েছে', format('আপনার %s জমা যাচাই হয়েছে', push_money(new.amount, true)),
        'Deposit verified', format('Your %s deposit was verified', push_money(new.amount, false)),
        '/money');
    else
      perform push_enqueue(array[m.user_id], 'deposit_rejected',
        'জমা বাতিল হয়েছে', format('আপনার %s জমা বাতিল করা হয়েছে', push_money(new.amount, true)),
        'Deposit rejected', format('Your %s deposit was rejected', push_money(new.amount, false)),
        '/money');
    end if;
  end if;
  return null;
end $$;
create trigger deposits_push after insert or update of status on public.deposits
  for each row execute function public.push_on_deposit();

create or replace function public.push_on_notice() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_mess text;
begin
  if new.deleted_at is null then
    select name into v_mess from messes where id = new.mess_id;
    perform push_enqueue(push_mess_users(new.mess_id, null, auth.uid()), 'notice',
      'নোটিশ: ' || new.title, coalesce(nullif(btrim(new.body), ''), v_mess),
      'Notice: ' || new.title, coalesce(nullif(btrim(new.body), ''), v_mess),
      '/more/notices/' || new.id);
  end if;
  return null;
end $$;
create trigger announcements_push after insert on public.announcements
  for each row execute function public.push_on_notice();

create or replace function public.push_on_bazar() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_mess text;
begin
  if new.deleted_at is null then
    select name into v_mess from messes where id = new.mess_id;
    perform push_enqueue(push_mess_users(new.mess_id, null, auth.uid()), 'bazar_added',
      'নতুন বাজার', format('%s: %s এর বাজার যোগ হয়েছে', v_mess, push_money(new.amount, true)),
      'New bazar', format('%s: %s bazar added', v_mess, push_money(new.amount, false)),
      '/bazar');
  end if;
  return null;
end $$;
create trigger bazars_push after insert on public.bazars
  for each row execute function public.push_on_bazar();

-- Per statement: a recurring-bill posting (one INSERT) sends one push per mess.
create or replace function public.push_on_expenses() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  r record;
begin
  for r in
    select n.mess_id, ms.name as mess, count(*) as cnt, sum(n.amount) as total, min(c.name) as cat
    from new_rows n
    join messes ms on ms.id = n.mess_id
    join expense_categories c on c.id = n.category_id
    where n.deleted_at is null
    group by n.mess_id, ms.name
  loop
    if r.cnt = 1 then
      perform push_enqueue(push_mess_users(r.mess_id, null, auth.uid()), 'expense_added',
        'নতুন খরচ', format('%s: %s %s', r.mess, r.cat, push_money(r.total, true)),
        'New expense', format('%s: %s %s', r.mess, r.cat, push_money(r.total, false)),
        '/money');
    else
      perform push_enqueue(push_mess_users(r.mess_id, null, auth.uid()), 'expense_added',
        'নতুন খরচ', format('%s: %sটি খরচ, মোট %s', r.mess,
                            translate(r.cnt::text, '0123456789', '০১২৩৪৫৬৭৮৯'), push_money(r.total, true)),
        'New expenses', format('%s: %s expenses, %s total', r.mess, r.cnt, push_money(r.total, false)),
        '/money');
    end if;
  end loop;
  return null;
end $$;
create trigger expenses_push after insert on public.expenses
  referencing new table as new_rows
  for each statement execute function public.push_on_expenses();

create or replace function public.push_on_month() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_mess text;
begin
  if new.status = 'closed' and (tg_op = 'INSERT' or old.status <> 'closed') then
    select name into v_mess from messes where id = new.mess_id;
    perform push_enqueue(push_mess_users(new.mess_id, null, null), 'month_closed',
      'মাস বন্ধ হয়েছে', format('%s: মাসের হিসাব চূড়ান্ত, আপনার ব্যালেন্স দেখুন', v_mess),
      'Month closed', format('%s: the month is final, check your balance', v_mess),
      '/money/months');
  end if;
  return null;
end $$;
create trigger months_push after insert or update of status on public.months
  for each row execute function public.push_on_month();

-- ── manager: remind members who owe money ────────────────────────────────
-- Each active app member (not the caller) with a negative balance in the
-- current period (member_balances, Dhaka date) gets their own amount.
-- Returns how many were queued. TOO_SOON within 10 minutes of the last run.
create or replace function public.send_due_reminders(p_mess uuid) returns int
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := require_user();
  v_from date;
  v_to   date;
  v_mess text;
  r      record;
  n      int := 0;
begin
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  perform assert_mess_writable(p_mess);
  if exists (select 1 from audit_log where mess_id = p_mess and action = 'send_due_reminders'
             and at > now() - interval '10 minutes') then
    perform fail('TOO_SOON');
  end if;
  select start_date, end_date into v_from, v_to
  from month_period(p_mess, (now() at time zone 'Asia/Dhaka')::date);
  select name into v_mess from messes where id = p_mess;
  for r in
    select m.user_id, -b.closing_balance as due
    from member_balances(p_mess, v_from, v_to) b
    join mess_members m on m.id = b.member_id
    where b.closing_balance < 0 and m.status = 'active' and m.user_id is not null and m.user_id <> v_uid
  loop
    n := n + push_enqueue(array[r.user_id], 'due_reminder',
      'বকেয়া পরিশোধ করুন', format('%s: আপনার বকেয়া %s, অনুগ্রহ করে জমা দিন', v_mess, push_money(r.due, true)),
      'Payment due', format('%s: you owe %s, please deposit', v_mess, push_money(r.due, false)),
      '/money');
  end loop;
  insert into audit_log (mess_id, actor_id, action, entity, new)
  values (p_mess, v_uid, 'send_due_reminders', 'push_outbox', jsonb_build_object('notified', n));
  return n;
end $$;

-- ── dispatcher side (service role) ───────────────────────────────────────
-- Claims up to p_limit unsent rows (≤ 5 tries, under 3 days old; a claim
-- older than 2 minutes counts as abandoned) with the recipient's tokens.
-- Also forgets rows older than 30 days.
create or replace function public.push_claim(p_limit int default 100)
returns table (id bigint, user_id uuid, title text, body text, data jsonb, tokens text[])
language plpgsql security definer set search_path = public as $$
begin
  delete from push_outbox o where o.created_at < now() - interval '30 days';
  return query
  with c as (
    select o.id from push_outbox o
    where o.sent_at is null and o.attempts < 5 and o.created_at > now() - interval '3 days'
      and (o.claimed_at is null or o.claimed_at < now() - interval '2 minutes')
    order by o.id
    limit least(greatest(coalesce(p_limit, 100), 1), 500)
    for update skip locked
  ), u as (
    update push_outbox o set attempts = o.attempts + 1, claimed_at = now()
    from c where o.id = c.id
    returning o.id, o.user_id, o.title, o.body, o.data
  )
  select u.id, u.user_id, u.title, u.body, u.data,
         coalesce((select array_agg(t.token order by t.updated_at desc) from device_tokens t
                   where t.user_id = u.user_id), '{}')
  from u order by u.id;
end $$;

-- ── account deletion also forgets devices and queued pushes ──────────────
create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = public as $$
begin
  perform set_config('meal_bazar.skip_suspension', 'on', true);
  perform delete_my_account_0007();
  perform set_config('meal_bazar.skip_suspension', '', true);
  delete from device_tokens where user_id = auth.uid();
  delete from push_outbox where user_id = auth.uid();
end $$;

-- ── grants ───────────────────────────────────────────────────────────────
revoke execute on function public.push_kick(), public.push_mess_users(uuid, public.member_role, uuid),
  public.push_enqueue(uuid[], text, text, text, text, text, text), public.push_claim(int)
  from public, anon, authenticated;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.push_claim(int) to service_role;
    grant select, update, delete on public.push_outbox to service_role;
    grant select, delete on public.device_tokens to service_role;
  end if;
end $$;
