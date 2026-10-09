-- 0024_meal_off_deadline: a manager-set "how long before the meal" deadline
-- for a member's own meal off/on, and a system message in the mess group when
-- a member switches. Rules: PRODUCT_RULES.md §1 (meal-off deadline).
-- Contract: DATABASE.md "Meal-off deadline (0024)".

-- ── schema ───────────────────────────────────────────────────────────────
-- Null = the old rule (previous day at meal_off_cutoff), so existing messes
-- keep their behaviour until the manager picks a lead in settings.
alter table public.messes
  add column meal_off_lead_minutes int check (meal_off_lead_minutes between 0 and 2880);

-- When a meal is served (Asia/Dhaka). Filled from the name when not given.
alter table public.meal_types add column serve_time time;

create or replace function public.default_serve_time(p_name text) returns time
language sql immutable as $$
  select case btrim(p_name)
           when 'সকাল' then '08:00' when 'দুপুর' then '13:30' when 'রাত' then '21:00'
           else '13:00' end::time;
$$;

alter table public.meal_types disable trigger user;   -- no audit/suspension noise for the backfill
update public.meal_types set serve_time = default_serve_time(name);
alter table public.meal_types enable trigger user;
alter table public.meal_types alter column serve_time set not null;

create or replace function public.fill_serve_time() returns trigger
language plpgsql as $$
begin
  new.serve_time := coalesce(new.serve_time, default_serve_time(new.name));
  return new;
end $$;
create trigger meal_types_serve_time before insert on public.meal_types
  for each row execute function public.fill_serve_time();

-- System messages (the app renders them as a centred pill from `meta`).
alter table public.messages
  add column kind text not null default 'user' check (kind in ('user', 'system')),
  add column meta jsonb;

-- ── the deadline: SQL is the only place it is computed ───────────────────
-- (date + serve_time) − lead in Asia/Dhaka; with no lead, the previous day
-- at meal_off_cutoff. Null for a meal type not in the mess. Security
-- invoker: callers see only messes they belong to.
create or replace function public.meal_off_deadline(p_mess uuid, p_date date, p_meal_type uuid)
returns timestamptz
language sql stable set search_path = public as $$
  select case
           when m.meal_off_lead_minutes is null
             then ((p_date - 1) + m.meal_off_cutoff) at time zone 'Asia/Dhaka'
           else ((p_date + t.serve_time) at time zone 'Asia/Dhaka')
                - make_interval(mins => m.meal_off_lead_minutes)
         end
  from messes m join meal_types t on t.mess_id = m.id
  where m.id = p_mess and t.id = p_meal_type;
$$;

-- Every meal type's deadline for each day in [p_from, p_to].
create or replace function public.meal_off_deadlines(p_mess uuid, p_from date, p_to date)
returns table (date date, meal_type_id uuid, deadline timestamptz)
language sql stable set search_path = public as $$
  select d::date, t.id, meal_off_deadline(p_mess, d::date, t.id)
  from generate_series(p_from, least(p_to, p_from + 31), interval '1 day') d
  cross join meal_types t
  where t.mess_id = p_mess;
$$;

-- ── the mess-group notice ────────────────────────────────────────────────
-- Bangla genitive for a meal name: রাত → রাতের, নাস্তা → নাস্তার, Lunch → Lunch-এর.
create or replace function public.bn_genitive(p_word text) returns text
language sql immutable as $$
  select case
           when p_word ~ '[\u09BE-\u09CC]$' then p_word || 'র'   -- ends in a vowel sign
           when p_word ~ '[\u0985-\u09B9\u09BC\u09CE\u09DC-\u09DF]$' then p_word || 'ের'
           else p_word || '-এর' end;
$$;

-- Posts "<day> <meal>-er মিল বন্ধ/চালু করেছেন" from the member into the
-- mess group. A second switch of the same meal within 2 minutes replaces the
-- previous notice (one push, tagged, so it replaces the older one too).
create or replace function public.post_meal_off_notice(
  p_mess uuid, p_member uuid, p_date date, p_meal_type uuid, p_off boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := auth.uid();
  v_thread uuid;
  v_name   text;
  v_meal   text;
  v_diff   int := p_date - (now() at time zone 'Asia/Dhaka')::date;
  v_day    text;
begin
  if coalesce(platform_default('features', 'messages'), 'true') = 'false'::jsonb
     or coalesce(platform_default('features', 'mess_group'), 'true') = 'false'::jsonb then
    return;
  end if;
  v_thread := ensure_mess_group(p_mess);
  select display_name into v_name from mess_members where id = p_member;
  select name into v_meal from meal_types where id = p_meal_type;
  v_day := case v_diff when 0 then 'আজ' when 1 then 'কাল' when -1 then 'গতকাল'
             else translate(to_char(p_date, 'DD/MM'), '0123456789', '০১২৩৪৫৬৭৮৯') end;

  delete from messages
  where thread_id = v_thread and kind = 'system' and sender_id = v_uid and hidden_at is null
    and created_at > now() - interval '2 minutes'
    and meta ->> 't' = 'meal_off' and meta ->> 'member' = p_member::text
    and meta ->> 'date' = p_date::text and meta ->> 'meal' = p_meal_type::text;

  insert into messages (thread_id, mess_id, sender_id, body, kind, meta)
  values (v_thread, p_mess, v_uid,
          v_day || ' ' || bn_genitive(v_meal) || ' মিল '
            || case when p_off then 'বন্ধ করেছেন' else 'আবার চালু করেছেন' end,
          'system',
          jsonb_build_object('t', 'meal_off', 'member', p_member, 'name', v_name,
                             'date', p_date, 'meal', p_meal_type, 'meal_name', v_meal,
                             'off', p_off));
  update message_threads set last_message_at = now() where id = v_thread;
end $$;
revoke execute on function public.post_meal_off_notice(uuid, uuid, date, uuid, boolean)
  from public, anon, authenticated;

-- ── member self-service, now with the per-meal deadline ──────────────────
-- Managers are never restricted by the deadline. A real change (off ↔ on)
-- posts the group notice; a repeat of the same state does not.
create or replace function public.set_my_meal_off(
  p_mess uuid, p_date date, p_meal_type uuid, p_off boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid     uuid := require_user();
  v_member  uuid;
  v_manager boolean := has_mess_role(p_mess, 'manager');
  v_was     boolean;
begin
  select id into v_member from mess_members
  where mess_id = p_mess and user_id = v_uid and status = 'active';
  if v_member is null then
    perform fail('NOT_MEMBER');
  end if;
  if not v_manager
     and coalesce(platform_default('features', 'member_meal_off'), 'true') = 'false'::jsonb then
    perform fail('FEATURE_OFF');
  end if;
  if not exists (select 1 from meal_types where id = p_meal_type and mess_id = p_mess and enabled) then
    perform fail('MEAL_TYPE_INVALID');
  end if;
  if not v_manager and now() >= meal_off_deadline(p_mess, p_date, p_meal_type) then
    perform fail('CUTOFF_PASSED');
  end if;

  select is_off into v_was from meal_entries
  where member_id = v_member and date = p_date and meal_type_id = p_meal_type;

  insert into meal_entries (mess_id, member_id, meal_type_id, date, count, is_off, source)
  values (p_mess, v_member, p_meal_type, p_date, case when p_off then 0 else 1 end, p_off, 'app')
  on conflict (member_id, date, meal_type_id) do update
    set is_off = excluded.is_off,
        count  = case when excluded.is_off then 0 else 1 end,
        source = 'app';

  if coalesce(v_was, false) <> p_off then
    perform post_meal_off_notice(p_mess, v_member, p_date, p_meal_type, p_off);
  end if;
end $$;
