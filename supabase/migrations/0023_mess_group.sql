-- 0023_mess_group: one group conversation per mess, on the 0022 tables.
-- A group thread is a message_threads row with kind = 'group' and no member;
-- every active/inactive member (and the managers) reads and posts to it. It is
-- created lazily by ensure_mess_group(). Managers hide any group message, a
-- member their own (soft delete, audited); otherwise messages stay
-- append-only. A new group message pushes every other active member (type
-- `group_message`, Android tag = thread id so newer pushes replace older).
-- Contract: DATABASE.md "Mess group (0023)".

-- ── schema ───────────────────────────────────────────────────────────────
alter table public.message_threads
  add column kind text not null default 'direct' check (kind in ('direct', 'group')),
  alter column member_id drop not null,
  add constraint message_threads_kind_member check ((kind = 'group') = (member_id is null));
create unique index message_threads_one_group on public.message_threads(mess_id) where kind = 'group';

alter table public.messages
  add column hidden_at timestamptz,
  add column hidden_by uuid references auth.users(id) on delete set null,
  drop constraint messages_body_check,
  add constraint messages_body_check
    check (hidden_at is not null or char_length(btrim(body)) between 1 and 1000);

-- The text of a hidden message, kept for the service role only (RLS on, no
-- policies): members can no longer read it, nothing is lost.
create table public.message_hidden_bodies (
  message_id uuid primary key references public.messages(id) on delete cascade,
  body       text not null
);
alter table public.message_hidden_bodies enable row level security;
revoke all on public.message_hidden_bodies from public, anon, authenticated;

-- ── visibility: a group (no member) is every current member's ────────────
create or replace function public.can_see_thread(p_mess uuid, p_member uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select has_mess_role(p_mess, 'manager') or exists (
    select 1 from mess_members
    where mess_id = p_mess and user_id = auth.uid() and status in ('active', 'inactive')
      and (p_member is null or id = p_member)
  );
$$;

-- Same columns as 0022 (left join: a group has no member) plus kind and
-- whether the last message is hidden. Hidden messages are never unread.
create or replace view public.message_thread_feed as
  select t.id, t.mess_id, t.member_id, t.subject, t.ref_type, t.ref_id, t.ref_label,
         t.status, t.created_by, t.created_at, t.updated_at, t.last_message_at,
         m.display_name as member_name,
         lm.body as last_body, lm.sender_id as last_sender_id,
         exists (
           select 1 from messages x
           where x.thread_id = t.id and x.sender_id is distinct from auth.uid() and x.hidden_at is null
             and x.created_at > coalesce((select r.read_at from message_reads r
                                          where r.thread_id = t.id and r.user_id = auth.uid()),
                                         '-infinity')
         ) as is_unread,
         t.kind,
         lm.hidden_at is not null as last_hidden
  from message_threads t
  left join mess_members m on m.id = t.member_id
  left join lateral (
    select x.body, x.sender_id, x.hidden_at from messages x
    where x.thread_id = t.id order by x.created_at desc, x.id desc limit 1
  ) lm on true
  where can_see_thread(t.mess_id, t.member_id);

-- "Needs attention" stays about member ↔ manager threads; group chatter is
-- counted by the app from the feed.
create or replace function public.unread_thread_count(p_mess uuid) returns int
language sql stable set search_path = public as $$
  select count(*)::int from message_thread_feed where mess_id = p_mess and is_unread and kind = 'direct';
$$;

-- ── RPCs ─────────────────────────────────────────────────────────────────
-- The mess's group thread id, created on first use. Any current member.
create or replace function public.ensure_mess_group(p_mess uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  perform require_user();
  if not is_mess_member(p_mess) then
    perform fail('NOT_MEMBER');
  end if;
  select id into v_id from message_threads where mess_id = p_mess and kind = 'group';
  if v_id is null then
    -- A system row, not user content: reading the group works while suspended.
    perform set_config('meal_bazar.skip_suspension', 'on', true);
    insert into message_threads (mess_id, kind, subject, created_by)
    values (p_mess, 'group', 'Mess group', null)
    on conflict (mess_id) where kind = 'group' do nothing
    returning id into v_id;
    perform set_config('meal_bazar.skip_suspension', '', true);
    if v_id is null then   -- a concurrent call won
      select id into v_id from message_threads where mess_id = p_mess and kind = 'group';
    end if;
  end if;
  return v_id;
end $$;

-- Hides a group message (idempotent): managers any, a member their own.
-- Direct-thread messages stay append-only. The text moves to
-- message_hidden_bodies; the audit row names the message, never its text.
create or replace function public.hide_message(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := require_user();
  x     messages;
  t     message_threads;
begin
  select * into x from messages where id = p_id;
  if not found then
    perform fail('NOT_MEMBER');
  end if;
  t := thread_for_caller(x.thread_id);
  if x.hidden_at is not null then
    return;
  end if;
  if t.kind <> 'group' or not (has_mess_role(t.mess_id, 'manager') or x.sender_id is not distinct from v_uid) then
    perform fail('NOT_MANAGER');
  end if;
  insert into message_hidden_bodies (message_id, body) values (x.id, x.body);
  update messages set body = '', hidden_at = now(), hidden_by = v_uid where id = x.id;
  insert into audit_log (mess_id, actor_id, action, entity, entity_id, old)
  values (t.mess_id, v_uid, 'hide_message', 'messages', x.id,
          jsonb_build_object('thread_id', t.id, 'sender_id', x.sender_id));
end $$;

-- ── platform flag `mess_group` (missing = on) ────────────────────────────
alter function public.platform_config_defaults() rename to platform_config_defaults_pre_mess_group;
create function public.platform_config_defaults() returns jsonb
language sql immutable as $$
  select jsonb_set(platform_config_defaults_pre_mess_group(), '{features,mess_group}', 'true');
$$;
update public.platform_config set value = value || '{"mess_group":true}'
where key = 'features' and not value ? 'mess_group';

-- ── push: an optional Android tag (newer pushes with it replace older) ────
-- The 0019 7-argument form keeps its callers and delegates here.
create or replace function public.push_enqueue(
  p_users uuid[], p_type text, p_title_bn text, p_body_bn text, p_title_en text, p_body_en text,
  p_route text, p_tag text
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
         jsonb_strip_nulls(jsonb_build_object('route', p_route, 'type', p_type, 'tag', p_tag))
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

create or replace function public.push_enqueue(
  p_users uuid[], p_type text, p_title_bn text, p_body_bn text, p_title_en text, p_body_en text,
  p_route text
) returns int
language sql security definer set search_path = public as $$
  select push_enqueue(p_users, p_type, p_title_bn, p_body_bn, p_title_en, p_body_en, p_route, null::text);
$$;

-- Direct threads as in 0022; a group message → every other active member.
create or replace function public.push_on_message() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  t      message_threads;
  m      mess_members;
  v_name text;
  v_mess text;
  v_to   uuid[];
begin
  if coalesce(platform_default('features', 'messages'), 'true') = 'false'::jsonb then
    return null;
  end if;
  select * into t from message_threads where id = new.thread_id;
  select display_name into v_name from mess_members
  where mess_id = t.mess_id and user_id = new.sender_id;
  if t.kind = 'group' then
    if coalesce(platform_default('features', 'mess_group'), 'true') = 'false'::jsonb then
      return null;
    end if;
    select name into v_mess from messes where id = t.mess_id;
    perform push_enqueue(push_mess_users(t.mess_id, null, new.sender_id), 'group_message',
      v_mess || ' · গ্রুপ', coalesce(v_name || ': ', '') || left(new.body, 80),
      v_mess || ' · group', coalesce(v_name || ': ', '') || left(new.body, 80),
      '/more/messages/' || t.id, t.id::text);
    return null;
  end if;
  select * into m from mess_members where id = t.member_id;
  if m.user_id is not distinct from new.sender_id then
    v_to := push_mess_users(t.mess_id, 'manager', new.sender_id);
  elsif m.status = 'active' and m.user_id is not null then
    v_to := array[m.user_id];
  end if;
  perform push_enqueue(v_to, 'message',
    'বার্তা: ' || t.subject, coalesce(v_name || ': ', '') || new.body,
    'Message: ' || t.subject, coalesce(v_name || ': ', '') || new.body,
    '/more/messages/' || t.id);
  return null;
end $$;

revoke execute on function public.push_enqueue(uuid[], text, text, text, text, text, text, text)
  from public, anon, authenticated;
