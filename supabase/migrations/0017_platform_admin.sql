-- 0017_platform_admin: Super Admin — platform config, suspension, admin RPCs,
-- branding bucket and write-only platform credentials. Contract: docs/platform-admin.md.

-- ── who is a platform admin ──────────────────────────────────────────────
-- Bootstrap (SQL editor, once): insert into platform_admins select id from auth.users where email = '…';
create table public.platform_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.platform_admins enable row level security;   -- no policies: RPCs only

create or replace function public.is_platform_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from platform_admins where user_id = auth.uid());
$$;
grant execute on function public.is_platform_admin() to authenticated;

create or replace function public.require_platform_admin() returns uuid
language plpgsql stable as $$
begin
  if not is_platform_admin() then
    perform fail('NOT_PLATFORM_ADMIN');
  end if;
  return auth.uid();
end $$;

-- ── audit ────────────────────────────────────────────────────────────────
create table public.platform_audit (
  id       bigint generated always as identity primary key,
  actor_id uuid,
  action   text not null,
  target   text,
  old      jsonb,
  new      jsonb,
  reason   text,
  at       timestamptz not null default now()
);
create index platform_audit_at_idx on public.platform_audit(at desc);
alter table public.platform_audit enable row level security;
create policy platform_audit_read on public.platform_audit for select using (is_platform_admin());

create or replace function public.platform_log(
  p_action text, p_target text, p_old jsonb, p_new jsonb, p_reason text default null
) returns void
language sql security definer set search_path = public as $$
  insert into platform_audit (actor_id, action, target, old, new, reason)
  values (auth.uid(), p_action, p_target, p_old, p_new, nullif(btrim(p_reason), ''));
$$;

-- ── config ───────────────────────────────────────────────────────────────
-- The seed values, also the fallback when a key is missing from platform_config.
create or replace function public.platform_config_defaults() returns jsonb
language sql immutable as $$
  select $json${
  "features": {"ai":true,"ai_meal_draft":true,"ai_bazar_scan":true,"receipts":true,"notices":true,
    "duty":true,"reminders":true,"export":true,"recurring":true,"split":true,"fixed_rate":true,
    "google_login":true,"email_login":true,"member_meal_off":true,"guest_meals":true,
    "member_deposits":true,"deposit_verification":true,"dashboard_charts":true,"pdf_report":true,
    "share_bills":true,"due_reminders":true,"cook_share":true,"bazar_picker":true,
    "meal_defaults":true,"audit_log":true,"offline_mode":true,"setup_checklist":true,"invite_qr":true},
  "ai": {"enabled":true,
    "text_chain":[{"provider":"gemini","model":"gemini-flash-latest"},{"provider":"openrouter","model":"openrouter/free"}],
    "vision_chain":[{"provider":"gemini","model":"gemini-flash-latest"},{"provider":"openrouter","model":"openrouter/free"}],
    "quota_meal_draft":30,"quota_bazar_draft":10,"timeout_ms":20000,"temperature":0.2,"allow_paid":false},
  "app": {"maintenance":false,"maintenance_message_bn":"","maintenance_message_en":"",
    "min_version":"1.0.0","latest_version":"1.0.0","update_message_bn":"","update_message_en":"",
    "support_email":"","support_whatsapp":"","privacy_url":"",
    "banner":{"active":false,"text_bn":"","text_en":"","level":"info"}},
  "defaults": {"month_start_day":1,"meal_off_cutoff":"22:00",
    "meal_types":[{"name":"সকাল","weight":0.5,"enabled":false},{"name":"দুপুর","weight":1,"enabled":true},
                  {"name":"রাত","weight":1,"enabled":true}],
    "expense_categories":[{"name":"বিদ্যুৎ","split":"equal"},{"name":"গ্যাস","split":"equal"},
      {"name":"ওয়াইফাই","split":"equal"},{"name":"পানি","split":"equal"},{"name":"বাসা ভাড়া","split":"equal"},
      {"name":"বুয়া","split":"equal"},{"name":"পরিষ্কার","split":"equal"},{"name":"মেরামত","split":"equal"},
      {"name":"অন্যান্য","split":"equal"}]},
  "catalogue": {"groups":[
    {"name":"চাল-ডাল-তেল","items":[{"name":"চাল","unit":"কেজি"},{"name":"ডাল","unit":"কেজি"},
      {"name":"আটা","unit":"কেজি"},{"name":"সয়াবিন তেল","unit":"লিটার"},{"name":"চিনি","unit":"কেজি"},
      {"name":"লবণ","unit":"কেজি"}]},
    {"name":"সবজি","items":[{"name":"আলু","unit":"কেজি"},{"name":"পেঁয়াজ","unit":"কেজি"},
      {"name":"টমেটো","unit":"কেজি"},{"name":"বেগুন","unit":"কেজি"},{"name":"কাঁচা মরিচ","unit":"গ্রাম"},
      {"name":"শাক","unit":"আঁটি"}]},
    {"name":"মাছ-মাংস-ডিম","items":[{"name":"ডিম","unit":"হালি"},{"name":"মুরগি","unit":"কেজি"},
      {"name":"রুই মাছ","unit":"কেজি"},{"name":"গরুর মাংস","unit":"কেজি"}]},
    {"name":"মসলা ও অন্যান্য","items":[{"name":"হলুদ","unit":"গ্রাম"},{"name":"মরিচ গুঁড়া","unit":"গ্রাম"},
      {"name":"আদা","unit":"গ্রাম"},{"name":"রসুন","unit":"গ্রাম"},{"name":"গ্যাস সিলিন্ডার","unit":"টি"}]}]},
  "payment_methods": [
    {"key":"cash","label_bn":"ক্যাশ","label_en":"Cash","enabled":true},
    {"key":"bkash","label_bn":"বিকাশ","label_en":"bKash","enabled":true},
    {"key":"nagad","label_bn":"নগদ","label_en":"Nagad","enabled":true},
    {"key":"bank","label_bn":"ব্যাংক","label_en":"Bank","enabled":true},
    {"key":"other","label_bn":"অন্যভাবে","label_en":"Other","enabled":true}],
  "branding": {"app_name_bn":"মিল বাজার","app_name_en":"Meal Bazar",
    "tagline_bn":"মেসের পুরো হিসাব, ফোন থেকেই","tagline_en":"Your whole mess, from your phone",
    "logo_url":null,"accent_light":"#C98A0B","accent_dark":"#E8B33A"}
}$json$::jsonb;
$$;

create table public.platform_config (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid
);
alter table public.platform_config enable row level security;   -- reads via get_platform_config()
insert into public.platform_config (key, value)
  select key, value from jsonb_each(public.platform_config_defaults());

-- One field of a config key, falling back to the seed value.
create or replace function public.platform_default(p_key text, p_field text) returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce((select value -> p_field from platform_config where key = p_key),
                  platform_config_defaults() -> p_key -> p_field);
$$;

create or replace function public.get_platform_config() returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_object_agg(key, value), '{}') from platform_config;
$$;
grant execute on function public.get_platform_config() to anon, authenticated;

-- jsonb type checks (CASE so a cast never runs on the wrong type).
create or replace function public.jb_str(v jsonb, lo int, hi int) returns boolean
language sql immutable as $$
  select case when jsonb_typeof(v) = 'string' then char_length(btrim(v #>> '{}')) between lo and hi
              else false end;
$$;
create or replace function public.jb_num(v jsonb, lo numeric, hi numeric, whole boolean default false)
returns boolean
language sql immutable as $$
  select case when jsonb_typeof(v) = 'number'
              then v::numeric between lo and hi and (not whole or v::numeric = trunc(v::numeric))
              else false end;
$$;
create or replace function public.jb_bool(v jsonb) returns boolean
language sql immutable as $$ select coalesce(jsonb_typeof(v) = 'boolean', false); $$;
-- Absent or matching.
create or replace function public.jb_opt_str(v jsonb, hi int) returns boolean
language sql immutable as $$ select v is null or jb_str(v, 0, hi); $$;
create or replace function public.jb_array(v jsonb, lo int, hi int) returns boolean
language sql immutable as $$
  select case when jsonb_typeof(v) = 'array' then jsonb_array_length(v) between lo and hi else false end;
$$;

create or replace function public.ai_chain_ok(c jsonb) returns boolean
language sql immutable as $$
  select jb_array(c, 1, 5) and not exists (
    select 1 from jsonb_array_elements(case when jsonb_typeof(c) = 'array' then c else '[]' end) e
    where not (coalesce(e ->> 'provider', '') in ('gemini', 'openrouter') and jb_str(e -> 'model', 1, 120))
  );
$$;

-- Raises UNKNOWN_CONFIG_KEY / INVALID_CONFIG.
create or replace function public.validate_platform_config(p_key text, v jsonb) returns void
language plpgsql stable set search_path = public as $$
declare
  ok boolean;
begin
  if not (platform_config_defaults() ? p_key) then
    perform fail('UNKNOWN_CONFIG_KEY');
  end if;
  ok := case p_key
    -- Unknown flags are allowed (the app ignores them); every value is a boolean.
    when 'features' then jsonb_typeof(v) = 'object'
      and not exists (select 1 from jsonb_each(v) f where jsonb_typeof(f.value) <> 'boolean')
    when 'ai' then jsonb_typeof(v) = 'object'
      and jb_bool(v -> 'enabled') and jb_bool(v -> 'allow_paid')
      and ai_chain_ok(v -> 'text_chain') and ai_chain_ok(v -> 'vision_chain')
      and jb_num(v -> 'quota_meal_draft', 0, 1000, true) and jb_num(v -> 'quota_bazar_draft', 0, 1000, true)
      and jb_num(v -> 'timeout_ms', 3000, 55000, true) and jb_num(v -> 'temperature', 0, 1)
      and jb_opt_str(v -> 'primary_model', 120) and jb_opt_str(v -> 'fallback_model', 120)
    when 'app' then jsonb_typeof(v) = 'object'
      and jb_bool(v -> 'maintenance')
      and coalesce((v ->> 'min_version') ~ '^\d{1,4}\.\d{1,4}\.\d{1,4}$', false)
      and coalesce((v ->> 'latest_version') ~ '^\d{1,4}\.\d{1,4}\.\d{1,4}$', false)
      and jsonb_typeof(v -> 'min_version') = 'string' and jsonb_typeof(v -> 'latest_version') = 'string'
      and jb_opt_str(v -> 'maintenance_message_bn', 500) and jb_opt_str(v -> 'maintenance_message_en', 500)
      and jb_opt_str(v -> 'update_message_bn', 500) and jb_opt_str(v -> 'update_message_en', 500)
      and jb_opt_str(v -> 'support_email', 200) and jb_opt_str(v -> 'support_whatsapp', 40)
      and jb_opt_str(v -> 'privacy_url', 500)
      and (v -> 'banner' is null or (
        jsonb_typeof(v -> 'banner') = 'object' and jb_bool(v -> 'banner' -> 'active')
        and coalesce(v -> 'banner' ->> 'level', '') in ('info', 'warning', 'critical')
        and jb_opt_str(v -> 'banner' -> 'text_bn', 200) and jb_opt_str(v -> 'banner' -> 'text_en', 200)))
    when 'defaults' then jsonb_typeof(v) = 'object'
      and jb_num(v -> 'month_start_day', 1, 28, true)
      and coalesce((v ->> 'meal_off_cutoff') ~ '^([01]\d|2[0-3]):[0-5]\d$', false)
      and jb_array(v -> 'meal_types', 1, 10)
      and not exists (select 1 from jsonb_array_elements(v -> 'meal_types') e
                      where not (jb_str(e -> 'name', 1, 30) and jb_num(e -> 'weight', 0, 5)
                                 and (e -> 'enabled' is null or jb_bool(e -> 'enabled'))))
      and jb_array(v -> 'expense_categories', 0, 30)
      and not exists (select 1 from jsonb_array_elements(v -> 'expense_categories') e
                      where not (jb_str(e -> 'name', 1, 30)
                                 and coalesce(e ->> 'split', '') in ('meal', 'equal')))
    when 'catalogue' then jsonb_typeof(v) = 'object'
      and jb_array(v -> 'groups', 0, 20)
      and not exists (select 1 from jsonb_array_elements(v -> 'groups') g
                      where not (jb_str(g -> 'name', 1, 40) and jb_array(g -> 'items', 0, 100)))
      and not exists (select 1 from jsonb_array_elements(v -> 'groups') g,
                                    jsonb_array_elements(g -> 'items') i
                      where not (jb_str(i -> 'name', 1, 60) and jb_opt_str(i -> 'unit', 12)))
    when 'payment_methods' then jb_array(v, 1, 10)
      and not exists (select 1 from jsonb_array_elements(v) e
                      where not (coalesce(e ->> 'key', '') = any (enum_range(null::pay_method)::text[])
                                 and jb_str(e -> 'label_bn', 1, 30) and jb_str(e -> 'label_en', 1, 30)
                                 and jb_bool(e -> 'enabled')))
      and (select count(distinct e ->> 'key') = count(*) from jsonb_array_elements(v) e)
    when 'branding' then jsonb_typeof(v) = 'object'
      and jb_str(v -> 'app_name_bn', 1, 40) and jb_str(v -> 'app_name_en', 1, 40)
      and jb_opt_str(v -> 'tagline_bn', 120) and jb_opt_str(v -> 'tagline_en', 120)
      and (jsonb_typeof(v -> 'logo_url') is distinct from 'string' or jb_str(v -> 'logo_url', 1, 500))
      and coalesce(jsonb_typeof(v -> 'logo_url'), 'null') in ('null', 'string')
      and coalesce((v ->> 'accent_light') ~ '^#[0-9A-Fa-f]{6}$', false)
      and coalesce((v ->> 'accent_dark') ~ '^#[0-9A-Fa-f]{6}$', false)
  end;
  if ok is not true then
    perform fail('INVALID_CONFIG');
  end if;
end $$;

create or replace function public.admin_set_config(p_key text, p_value jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := require_platform_admin();
  v_old jsonb;
begin
  perform validate_platform_config(p_key, p_value);
  select value into v_old from platform_config where key = p_key;
  insert into platform_config (key, value, updated_at, updated_by)
  values (p_key, p_value, now(), v_uid)
  on conflict (key) do update set value = excluded.value, updated_at = now(), updated_by = v_uid;
  perform platform_log('set_config', p_key, v_old, p_value);
end $$;

-- ── suspension ───────────────────────────────────────────────────────────
alter table public.messes
  add column suspended_at     timestamptz,
  add column suspended_reason text check (char_length(suspended_reason) <= 300);
alter table public.profiles
  add column suspended_at     timestamptz,
  add column suspended_reason text check (char_length(suspended_reason) <= 300);

-- Refuses writes by a suspended user (USER_SUSPENDED) or to a suspended mess
-- (MESS_SUSPENDED). Platform admins and account deletion are exempt.
create or replace function public.assert_mess_writable(p_mess uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if is_platform_admin() or coalesce(current_setting('meal_bazar.skip_suspension', true), '') = 'on' then
    return;
  end if;
  if exists (select 1 from profiles where id = auth.uid() and suspended_at is not null) then
    perform fail('USER_SUSPENDED');
  end if;
  if exists (select 1 from messes where id = p_mess and suspended_at is not null) then
    perform fail('MESS_SUSPENDED');
  end if;
end $$;

create or replace function public.guard_suspension() returns trigger
language plpgsql as $$
declare
  k     text  := case when tg_table_name = 'messes' then 'id' else 'mess_id' end;
  v_old jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) end;
  v_new jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) end;
begin
  perform assert_mess_writable((coalesce(v_new, v_old) ->> k)::uuid);
  if tg_op = 'UPDATE' then
    if (v_old ->> k) is distinct from (v_new ->> k) then
      perform assert_mess_writable((v_old ->> k)::uuid);
    end if;
    -- Only platform admins set suspension (messes, profiles).
    if (v_old -> 'suspended_at', v_old -> 'suspended_reason')
       is distinct from (v_new -> 'suspended_at', v_new -> 'suspended_reason')
       and not is_platform_admin() then
      perform fail('NOT_PLATFORM_ADMIN');
    end if;
  end if;
  return coalesce(new, old);
end $$;

-- Named *_suspension so it fires after the *_mess triggers that fill mess_id.
do $$
declare t text;
begin
  foreach t in array array['messes', 'profiles', 'mess_members', 'mess_invites', 'meal_types',
                           'meal_entries', 'bazars', 'bazar_items', 'expense_categories', 'expenses',
                           'expense_shares', 'deposits', 'months', 'ai_usage', 'announcements',
                           'bazar_duties', 'recurring_expenses', 'recurring_applied', 'meal_defaults'] loop
    execute format('create trigger %1$s_suspension before insert or update or delete on public.%1$s
                    for each row execute function public.guard_suspension()', t);
  end loop;
end $$;

-- A suspended user (or a member of a suspended mess) may still delete their account.
alter function public.delete_my_account() rename to delete_my_account_0007;
revoke execute on function public.delete_my_account_0007() from public, anon, authenticated;
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = public as $$
begin
  perform set_config('meal_bazar.skip_suspension', 'on', true);
  perform delete_my_account_0007();
  perform set_config('meal_bazar.skip_suspension', '', true);
end $$;

-- ── new messes follow platform defaults ──────────────────────────────────
create or replace function public.seed_mess_defaults() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into meal_types (mess_id, name, sort_order, weight, enabled)
  select new.id, e ->> 'name', o - 1, (e ->> 'weight')::numeric, coalesce((e ->> 'enabled')::boolean, true)
  from jsonb_array_elements(platform_default('defaults', 'meal_types')) with ordinality t(e, o);
  return null;
end $$;

create or replace function public.seed_expense_categories() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into expense_categories (mess_id, name, default_split, sort_order)
  select new.id, e ->> 'name', (e ->> 'split')::split_method, o - 1
  from jsonb_array_elements(platform_default('defaults', 'expense_categories')) with ordinality t(e, o);
  return null;
end $$;

-- Same signature as 0001; month_start_day (when not given) and the meal-off
-- cutoff come from platform defaults.
create or replace function public.create_mess(
  p_name text, p_display_name text, p_month_start_day smallint default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := require_user();
  v_mess uuid;
begin
  insert into messes (name, month_start_day, meal_off_cutoff, created_by)
  values (btrim(p_name),
          coalesce(p_month_start_day, (platform_default('defaults', 'month_start_day') #>> '{}')::smallint, 1),
          coalesce((platform_default('defaults', 'meal_off_cutoff') #>> '{}')::time, '22:00'),
          v_uid)
  returning id into v_mess;

  perform set_config('meal_bazar.trusted', 'on', true);
  insert into mess_members (mess_id, user_id, display_name, role, status)
  values (v_mess, v_uid, btrim(p_display_name), 'manager', 'active');
  perform set_config('meal_bazar.trusted', '', true);
  return v_mess;
end $$;

-- ── admin RPCs ───────────────────────────────────────────────────────────
create or replace function public.admin_stats() returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  perform require_platform_admin();
  return jsonb_build_object(
    'users_total',      (select count(*) from profiles where deleted_at is null),
    'users_7d',         (select count(*) from profiles where deleted_at is null and created_at > now() - interval '7 days'),
    'messes_total',     (select count(*) from messes where deleted_at is null),
    'messes_active_7d', (select count(distinct mess_id) from audit_log where at > now() - interval '7 days'),
    'meals_7d',         (select count(*) from meal_entries where created_at > now() - interval '7 days'),
    'bazars_7d',        (select count(*) from bazars where deleted_at is null and created_at > now() - interval '7 days'),
    'ai_calls_7d',      (select coalesce(sum(count), 0) from ai_usage where day > current_date - 7),
    'suspended_messes', (select count(*) from messes where deleted_at is null and suspended_at is not null),
    'deletion_pending', (select count(*) from deletion_requests where processed_at is null));
end $$;

create or replace function public.admin_list_messes(p_search text default null, p_limit int default 50, p_offset int default 0)
returns table (id uuid, name text, created_at timestamptz, member_count int, manager_names text,
               last_activity timestamptz, suspended_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  perform require_platform_admin();
  return query
  select m.id, m.name, m.created_at,
         (select count(*)::int from mess_members x where x.mess_id = m.id and x.status in ('active', 'inactive')),
         (select string_agg(x.display_name, ', ' order by x.display_name) from mess_members x
          where x.mess_id = m.id and x.role = 'manager' and x.status = 'active'),
         (select max(a.at) from audit_log a where a.mess_id = m.id),
         m.suspended_at
  from messes m
  where m.deleted_at is null
    and (coalesce(btrim(p_search), '') = '' or m.name ilike '%' || btrim(p_search) || '%'
         or m.id::text = btrim(p_search))
  order by 6 desc nulls last, m.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200) offset greatest(coalesce(p_offset, 0), 0);
end $$;

create or replace function public.admin_list_users(p_search text default null, p_limit int default 50, p_offset int default 0)
returns table (id uuid, email text, full_name text, created_at timestamptz, last_sign_in_at timestamptz,
               mess_count int, suspended_at timestamptz, is_admin boolean)
language plpgsql stable security definer set search_path = public as $$
begin
  perform require_platform_admin();
  return query
  select u.id, u.email::text, p.full_name, u.created_at, u.last_sign_in_at,
         (select count(*)::int from mess_members x where x.user_id = u.id and x.status in ('active', 'inactive')),
         p.suspended_at,
         exists (select 1 from platform_admins a where a.user_id = u.id)
  from auth.users u
  left join profiles p on p.id = u.id
  where coalesce(btrim(p_search), '') = ''
     or u.email ilike '%' || btrim(p_search) || '%'
     or p.full_name ilike '%' || btrim(p_search) || '%'
     or u.phone ilike '%' || btrim(p_search) || '%'
     or u.id::text = btrim(p_search)
  order by u.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200) offset greatest(coalesce(p_offset, 0), 0);
end $$;

create or replace function public.admin_set_mess_suspended(p_mess uuid, p_suspended boolean, p_reason text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v messes%rowtype;
begin
  perform require_platform_admin();
  if p_suspended and coalesce(btrim(p_reason), '') = '' then
    perform fail('REASON_REQUIRED');
  end if;
  select * into v from messes where id = p_mess;
  if v.id is null then
    perform fail('NOT_FOUND');
  end if;
  update messes
  set suspended_at = case when p_suspended then coalesce(v.suspended_at, now()) end,
      suspended_reason = case when p_suspended then btrim(p_reason) end
  where id = p_mess;
  perform platform_log(case when p_suspended then 'suspend_mess' else 'unsuspend_mess' end, p_mess::text,
    jsonb_build_object('suspended_at', v.suspended_at, 'suspended_reason', v.suspended_reason),
    jsonb_build_object('suspended', p_suspended), p_reason);
end $$;

create or replace function public.admin_set_user_suspended(p_user uuid, p_suspended boolean, p_reason text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v profiles%rowtype;
begin
  perform require_platform_admin();
  if p_suspended and coalesce(btrim(p_reason), '') = '' then
    perform fail('REASON_REQUIRED');
  end if;
  select * into v from profiles where id = p_user;
  if v.id is null then
    perform fail('NOT_FOUND');
  end if;
  update profiles
  set suspended_at = case when p_suspended then coalesce(v.suspended_at, now()) end,
      suspended_reason = case when p_suspended then btrim(p_reason) end
  where id = p_user;
  perform platform_log(case when p_suspended then 'suspend_user' else 'unsuspend_user' end, p_user::text,
    jsonb_build_object('suspended_at', v.suspended_at, 'suspended_reason', v.suspended_reason),
    jsonb_build_object('suspended', p_suspended), p_reason);
end $$;

-- Grants or revokes platform admin by email. The last admin cannot be removed.
create or replace function public.admin_set_admin(p_email text, p_is_admin boolean) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid;
begin
  perform require_platform_admin();
  select id into v_user from auth.users where lower(email) = lower(btrim(p_email));
  if v_user is null then
    perform fail('USER_NOT_FOUND');
  end if;
  if p_is_admin then
    insert into platform_admins (user_id) values (v_user) on conflict do nothing;
  else
    if exists (select 1 from platform_admins where user_id = v_user)
       and (select count(*) from platform_admins) <= 1 then
      perform fail('LAST_ADMIN');
    end if;
    delete from platform_admins where user_id = v_user;
  end if;
  perform platform_log(case when p_is_admin then 'grant_admin' else 'revoke_admin' end, v_user::text,
    null, jsonb_build_object('email', p_email));
end $$;

create or replace function public.admin_ai_usage(p_days int default 30)
returns table (day date, feature text, calls bigint)
language plpgsql stable security definer set search_path = public as $$
begin
  perform require_platform_admin();
  return query
  select u.day, u.feature, sum(u.count)::bigint
  from ai_usage u
  where u.day > current_date - least(greatest(coalesce(p_days, 30), 1), 366)
  group by u.day, u.feature
  order by u.day desc, u.feature;
end $$;

create or replace function public.admin_deletion_queue()
returns table (user_id uuid, requested_at timestamptz, processed_at timestamptz, last_error text)
language plpgsql stable security definer set search_path = public as $$
begin
  perform require_platform_admin();
  return query
  select d.user_id, d.requested_at, d.processed_at, d.last_error
  from deletion_requests d
  order by d.processed_at is null desc, d.requested_at desc
  limit 500;
end $$;

-- ── platform credentials (write-only) ────────────────────────────────────
create table public.platform_secrets (
  name       text primary key
             check (name in ('GEMINI_API_KEY', 'OPENROUTER_API_KEY', 'SMS_PROVIDER_KEY', 'SMTP_PASSWORD')),
  value      text not null,
  updated_at timestamptz not null default now(),
  updated_by uuid
);
alter table public.platform_secrets enable row level security;   -- no policies: service_role only
revoke all on public.platform_secrets from public, anon, authenticated;

-- null or '' deletes. The value is never logged.
create or replace function public.admin_set_secret(p_name text, p_value text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := require_platform_admin();
begin
  if p_name is null or p_name not in ('GEMINI_API_KEY', 'OPENROUTER_API_KEY', 'SMS_PROVIDER_KEY', 'SMTP_PASSWORD') then
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

-- Names and the last 4 characters (hidden for short values); never the value.
create or replace function public.admin_list_secrets()
returns table (name text, last4 text, updated_at timestamptz, updated_by uuid)
language plpgsql stable security definer set search_path = public as $$
begin
  perform require_platform_admin();
  return query
  select s.name, case when char_length(s.value) >= 12 then right(s.value, 4) else '••••' end,
         s.updated_at, s.updated_by
  from platform_secrets s order by s.name;
end $$;

create or replace function public.get_platform_secrets() returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_object_agg(name, value), '{}') from platform_secrets;
$$;
revoke execute on function public.get_platform_secrets() from public, anon, authenticated;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.get_platform_secrets() to service_role;
  end if;
end $$;

-- ── branding bucket (public read, admin write) ───────────────────────────
-- A function so the SQL test can replay it against its storage stub.
create or replace function public.setup_branding_storage() returns void
language plpgsql as $$
begin
  if not exists (select 1 from pg_namespace where nspname = 'storage') then
    return;
  end if;
  insert into storage.buckets (id, name, public) values ('branding', 'branding', true)
  on conflict (id) do nothing;
  drop policy if exists branding_read on storage.objects;
  drop policy if exists branding_insert on storage.objects;
  drop policy if exists branding_update on storage.objects;
  drop policy if exists branding_delete on storage.objects;
  create policy branding_read on storage.objects for select using (bucket_id = 'branding');
  create policy branding_insert on storage.objects for insert
    with check (bucket_id = 'branding' and public.is_platform_admin());
  create policy branding_update on storage.objects for update
    using (bucket_id = 'branding' and public.is_platform_admin())
    with check (bucket_id = 'branding' and public.is_platform_admin());
  create policy branding_delete on storage.objects for delete
    using (bucket_id = 'branding' and public.is_platform_admin());
end $$;
revoke execute on function public.setup_branding_storage() from public, anon, authenticated;
select public.setup_branding_storage();
