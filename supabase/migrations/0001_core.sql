-- 0001_core: profiles, messes, members, invites, audit log, RLS.
-- Rules: PRODUCT_RULES.md §5–6. Patterns: DATABASE.md.

-- ── helpers ──────────────────────────────────────────────────────────────
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- Raise a short message key that the app maps to bn/en text.
create or replace function public.fail(p_key text) returns void
language plpgsql as $$
begin
  raise exception '%', p_key using errcode = 'P0001';
end $$;

-- ── tables ───────────────────────────────────────────────────────────────
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null default '' check (char_length(full_name) <= 80),
  phone       text,
  avatar_path text,
  locale      text not null default 'bn' check (locale in ('bn', 'en')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table public.messes (
  id              uuid primary key default gen_random_uuid(),
  name            text not null check (char_length(btrim(name)) between 2 and 60),
  address         text check (char_length(address) <= 200),
  month_start_day smallint not null default 1 check (month_start_day between 1 and 28),
  currency        text not null default '৳' check (char_length(currency) <= 5),
  meal_off_cutoff time not null default '22:00',
  ai_settings     jsonb not null default '{"enabled": true, "pseudonymise": true}',
  created_by      uuid references auth.users(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);

create type public.member_role as enum ('manager', 'member');
create type public.member_status as enum ('pending', 'active', 'inactive', 'left');

-- user_id is null for members who do not use the app (the manager enters their meals).
-- Financial rows reference mess_members.id, so history survives account deletion.
create table public.mess_members (
  id           uuid primary key default gen_random_uuid(),
  mess_id      uuid not null references public.messes(id) on delete cascade,
  user_id      uuid references auth.users(id) on delete set null,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 40),
  role         public.member_role not null default 'member',
  status       public.member_status not null default 'active',
  joined_on    date not null default current_date,
  left_on      date,
  room         text check (char_length(room) <= 20),
  notes        text check (char_length(notes) <= 300),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (mess_id, user_id),
  check (left_on is null or left_on >= joined_on),
  check ((status = 'left') = (left_on is not null))
);
create index mess_members_user_idx on public.mess_members(user_id);

create table public.mess_invites (
  id         uuid primary key default gen_random_uuid(),
  mess_id    uuid not null references public.messes(id) on delete cascade,
  code       text not null unique check (code ~ '^[A-Z2-9]{6}$'),
  created_by uuid references auth.users(id) on delete set null,
  expires_at timestamptz not null default now() + interval '7 days',
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create index mess_invites_mess_idx on public.mess_invites(mess_id);

create table public.audit_log (
  id        bigint generated always as identity primary key,
  mess_id   uuid not null references public.messes(id) on delete cascade,
  actor_id  uuid,
  action    text not null,              -- insert | update | delete | <rpc name>
  entity    text not null,
  entity_id uuid,
  old       jsonb,
  new       jsonb,
  source    text not null default 'app' check (source in ('app', 'ai', 'system')),
  reason    text,
  at        timestamptz not null default now()
);
create index audit_log_mess_at_idx on public.audit_log(mess_id, at desc);

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger messes_updated_at before update on public.messes
  for each row execute function public.set_updated_at();
create trigger mess_members_updated_at before update on public.mess_members
  for each row execute function public.set_updated_at();

-- ── membership helpers (security definer: avoids recursive RLS) ─────────
create or replace function public.is_mess_member(p_mess uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from mess_members
    where mess_id = p_mess and user_id = auth.uid() and status in ('active', 'inactive')
  );
$$;

create or replace function public.has_mess_role(p_mess uuid, p_role public.member_role)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from mess_members
    where mess_id = p_mess and user_id = auth.uid() and status = 'active' and role = p_role
  );
$$;

create or replace function public.shares_mess_with(p_user uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from mess_members a
    join mess_members b on b.mess_id = a.mess_id
    where a.user_id = auth.uid() and a.status in ('active', 'inactive')
      and b.user_id = p_user
  );
$$;

-- ── audit ────────────────────────────────────────────────────────────────
create or replace function public.audit_row() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_old jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) end;
  v_new jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) end;
  v_row jsonb := coalesce(v_new, v_old);
begin
  if tg_op = 'UPDATE' and (v_old - 'updated_at') = (v_new - 'updated_at') then
    return null;
  end if;
  insert into audit_log (mess_id, actor_id, action, entity, entity_id, old, new, source)
  values (
    coalesce((v_row ->> 'mess_id')::uuid, (v_row ->> 'id')::uuid),
    auth.uid(), lower(tg_op), tg_table_name, (v_row ->> 'id')::uuid, v_old, v_new,
    coalesce(v_row ->> 'source', 'app')
  );
  return null;
end $$;

create trigger messes_audit after update on public.messes
  for each row execute function public.audit_row();
create trigger mess_members_audit after insert or update or delete on public.mess_members
  for each row execute function public.audit_row();

-- ── member guards ────────────────────────────────────────────────────────
-- user_id may only be set by trusted RPCs (create_mess, join_mess); otherwise a
-- manager could attach an arbitrary account to their mess.
create or replace function public.guard_member_row() returns trigger
language plpgsql as $$
declare
  v_trusted boolean := coalesce(current_setting('meal_bazar.trusted', true), '') = 'on';
begin
  if tg_op = 'INSERT' then
    if new.user_id is not null and not v_trusted then
      perform fail('USER_LINK_FORBIDDEN');
    end if;
    return new;
  end if;

  if new.mess_id <> old.mess_id then
    perform fail('IMMUTABLE_FIELD');
  end if;
  if new.user_id is distinct from old.user_id and not v_trusted then
    perform fail('USER_LINK_FORBIDDEN');
  end if;
  -- A mess must always keep one active manager.
  if old.role = 'manager' and old.status = 'active'
     and not (new.role = 'manager' and new.status = 'active')
     and not exists (
       select 1 from mess_members
       where mess_id = old.mess_id and id <> old.id and role = 'manager' and status = 'active'
     ) then
    perform fail('LAST_MANAGER');
  end if;
  return new;
end $$;

create trigger mess_members_guard before insert or update on public.mess_members
  for each row execute function public.guard_member_row();

-- ── new auth user → profile ──────────────────────────────────────────────
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, phone) values (new.id, new.phone) on conflict do nothing;
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── RPCs ─────────────────────────────────────────────────────────────────
create or replace function public.require_user() returns uuid
language plpgsql stable as $$
begin
  if auth.uid() is null then
    perform fail('NOT_AUTHENTICATED');
  end if;
  return auth.uid();
end $$;

-- Creates a mess; the caller becomes its first active manager.
create or replace function public.create_mess(
  p_name text, p_display_name text, p_month_start_day smallint default 1
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := require_user();
  v_mess uuid;
begin
  insert into messes (name, month_start_day, created_by)
  values (btrim(p_name), p_month_start_day, v_uid)
  returning id into v_mess;

  perform set_config('meal_bazar.trusted', 'on', true);
  insert into mess_members (mess_id, user_id, display_name, role, status)
  values (v_mess, v_uid, btrim(p_display_name), 'manager', 'active');
  perform set_config('meal_bazar.trusted', '', true);
  return v_mess;
end $$;

-- Generates a fresh 6-character invite code (manager only).
create or replace function public.create_invite(p_mess uuid) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
begin
  perform require_user();
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  loop
    select string_agg(substr(v_alphabet, 1 + floor(random() * 32)::int, 1), '')
      into v_code from generate_series(1, 6);
    begin
      insert into mess_invites (mess_id, code, created_by) values (p_mess, v_code, auth.uid());
      return v_code;
    exception when unique_violation then
      -- collision: try another code
    end;
  end loop;
end $$;

-- Requests to join a mess by code; creates a pending membership for manager approval.
create or replace function public.join_mess(p_code text, p_display_name text) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := require_user();
  v_mess   uuid;
  v_member mess_members%rowtype;
begin
  select mess_id into v_mess from mess_invites
  where code = upper(btrim(p_code)) and revoked_at is null and expires_at > now();
  if v_mess is null then
    perform fail('INVALID_INVITE');
  end if;

  select * into v_member from mess_members where mess_id = v_mess and user_id = v_uid;
  if v_member.id is not null and v_member.status <> 'left' then
    perform fail('ALREADY_MEMBER');
  end if;

  perform set_config('meal_bazar.trusted', 'on', true);
  if v_member.id is not null then
    update mess_members set status = 'pending', left_on = null where id = v_member.id;
  else
    insert into mess_members (mess_id, user_id, display_name, status)
    values (v_mess, v_uid, btrim(p_display_name), 'pending')
    returning * into v_member;
  end if;
  perform set_config('meal_bazar.trusted', '', true);
  return v_member.id;
end $$;

-- ── RLS ──────────────────────────────────────────────────────────────────
alter table public.profiles     enable row level security;
alter table public.messes       enable row level security;
alter table public.mess_members enable row level security;
alter table public.mess_invites enable row level security;
alter table public.audit_log    enable row level security;

create policy profiles_read on public.profiles for select
  using (id = auth.uid() or shares_mess_with(id));
create policy profiles_update on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

create policy messes_read on public.messes for select
  using (is_mess_member(id));
create policy messes_update on public.messes for update
  using (has_mess_role(id, 'manager')) with check (has_mess_role(id, 'manager'));

-- A pending requester can see their own row so the app can show "waiting for approval".
create policy members_read on public.mess_members for select
  using (is_mess_member(mess_id) or user_id = auth.uid());
create policy members_insert on public.mess_members for insert
  with check (has_mess_role(mess_id, 'manager'));
create policy members_update on public.mess_members for update
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));
-- Only unapproved requests can be deleted (rejection); real members are marked 'left'.
create policy members_delete on public.mess_members for delete
  using (has_mess_role(mess_id, 'manager') and status = 'pending');

create policy invites_manage on public.mess_invites for all
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));

create policy audit_read on public.audit_log for select
  using (is_mess_member(mess_id));
